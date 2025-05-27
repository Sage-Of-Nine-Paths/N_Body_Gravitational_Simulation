#include <iostream>
#include <fstream>
#include <vector>
#include <chrono>
#include <cmath>
#include <string>
#include <cstdlib>

#define N 1000
#define STEPS 300
#define DT 0.01f
#define G 0.5
// 6.67430e-11f

struct Body {
    float x, y;
    float vx, vy;
    float mass;
};

float computeSpeed(const Body& b) {
    return std::sqrt(b.vx * b.vx + b.vy * b.vy);
}

void initializeBodies(std::vector<Body>& bodies) {
    bodies.resize(N);
    for (int i = 0; i < N; ++i) {
        bodies[i].x = static_cast<float>(rand()) / RAND_MAX * 100.0f;
        bodies[i].y = static_cast<float>(rand()) / RAND_MAX * 100.0f;
        bodies[i].vx = 0.0f;
        bodies[i].vy = 0.0f;
        bodies[i].mass = static_cast<float>(rand()) / RAND_MAX * 1e3f + 1.0f;
    }
}

void saveStep(const std::vector<Body>& bodies, const std::string& folder, int step) {
    std::ofstream fout(folder + "/positions_step_" + std::to_string(step) + ".txt");
    if (!fout) {
        std::cerr << "Error opening file for writing: " << folder << std::endl;
        return;
    }
    for (const auto& b : bodies) {
        fout << b.x << " " << b.y << " " << computeSpeed(b) << "\n";
    }
}

void simulateCPU(std::vector<Body>& bodies, const std::string& folder) {
    std::string cmd = "mkdir -p " + folder;
    system(cmd.c_str());

    for (int step = 0; step < STEPS; ++step) {
        std::vector<Body> next = bodies;
        for (int i = 0; i < N; ++i) {
            float fx = 0, fy = 0;
            for (int j = 0; j < N; ++j) {
                if (i == j) continue;
                float dx = bodies[j].x - bodies[i].x;
                float dy = bodies[j].y - bodies[i].y;
                float distSqr = dx * dx + dy * dy + 1e-4f;
                float invDist = 1.0f / std::sqrt(distSqr);
                float invDist3 = invDist * invDist * invDist;
                float f = G * bodies[i].mass * bodies[j].mass * invDist3;
                fx += f * dx;
                fy += f * dy;
            }
            next[i].vx += DT * fx / bodies[i].mass;
            next[i].vy += DT * fy / bodies[i].mass;
            next[i].x += DT * next[i].vx;
            next[i].y += DT * next[i].vy;
        }
        bodies = next;
        saveStep(bodies, folder, step);

        if(step % 50 == 0)
            std::cout << "[CPU] Step " << step << " done\n";
    }
}

__global__ void updateBodies(Body* bodies, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;

    float fx = 0, fy = 0;
    for (int j = 0; j < n; ++j) {
        if (i == j) continue;
        float dx = bodies[j].x - bodies[i].x;
        float dy = bodies[j].y - bodies[i].y;
        float distSqr = dx * dx + dy * dy + 1e-4f;
        float invDist = rsqrtf(distSqr);
        float invDist3 = invDist * invDist * invDist;
        float f = G * bodies[i].mass * bodies[j].mass * invDist3;
        fx += f * dx;
        fy += f * dy;
    }

    bodies[i].vx += DT * fx / bodies[i].mass;
    bodies[i].vy += DT * fy / bodies[i].mass;
    bodies[i].x += DT * bodies[i].vx;
    bodies[i].y += DT * bodies[i].vy;
}

inline void checkCuda(cudaError_t err, const char* msg) {
    if (err != cudaSuccess) {
        std::cerr << "CUDA Error: " << msg << " - " << cudaGetErrorString(err) << std::endl;
        exit(1);
    }
}

void simulateGPU(std::vector<Body>& bodies, const std::string& folder) {
    std::string cmd = "mkdir -p " + folder;
    system(cmd.c_str());

    Body* d_bodies = nullptr;
    checkCuda(cudaMalloc(&d_bodies, N * sizeof(Body)), "cudaMalloc failed");
    checkCuda(cudaMemcpy(d_bodies, bodies.data(), N * sizeof(Body), cudaMemcpyHostToDevice), "cudaMemcpy H2D failed");

    for (int step = 0; step < STEPS; ++step) {
        updateBodies<<<(N + 255) / 256, 256>>>(d_bodies, N);
        cudaError_t err = cudaDeviceSynchronize();
        if (err != cudaSuccess) {
            std::cerr << "CUDA kernel error at step " << step << ": " << cudaGetErrorString(err) << std::endl;
            break;
        }
        checkCuda(cudaMemcpy(bodies.data(), d_bodies, N * sizeof(Body), cudaMemcpyDeviceToHost), "cudaMemcpy D2H failed");

        saveStep(bodies, folder, step);

        if(step % 50 == 0)
            std::cout << "[GPU] Step " << step << " done\n";
    }

    cudaFree(d_bodies);
}

int main() {
    std::vector<Body> bodiesCPU, bodiesGPU;
    initializeBodies(bodiesCPU);
    bodiesGPU = bodiesCPU;

    std::cout << "Starting CPU simulation...\n";
    auto startCPU = std::chrono::high_resolution_clock::now();
    simulateCPU(bodiesCPU, "cpu_output");
    auto endCPU = std::chrono::high_resolution_clock::now();

    std::cout << "Starting GPU simulation...\n";
    auto startGPU = std::chrono::high_resolution_clock::now();
    simulateGPU(bodiesGPU, "gpu_output");
    auto endGPU = std::chrono::high_resolution_clock::now();

    auto cpuMs = std::chrono::duration_cast<std::chrono::milliseconds>(endCPU - startCPU).count();
    auto gpuMs = std::chrono::duration_cast<std::chrono::milliseconds>(endGPU - startGPU).count();

    std::cout << "CPU Time: " << cpuMs << " ms\n";
    std::cout << "GPU Time: " << gpuMs << " ms\n";

    return 0;
}
