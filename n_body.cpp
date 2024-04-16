/*
    Authored by :: Aniruddha Date
    Date Created:: 14 March 2024
*/

#include <bits/stdc++.h>
using namespace std;
using ld = long double;

const ld G = 3;
const ld dt = 0.001;

// open file to write data
ofstream outFile("data.txt", ios::app);

struct Body
{
    ld Mass; // mass
    ld X, Y; // position
    ld Vx, Vy; // velocity
    ld Ax, Ay; // acceleration
    Body(ld mass, ld x, ld y, ld vx, ld vy, ld ax, ld ay) :
        Mass(mass), X(x), Y(y), Vx(vx), Vy(vy), Ax(ax), Ay(ay) { }
};

ld abs_force(Body &P1, Body &P2)
{
    ld dx = P1.X - P2.X;
    ld dy = P1.Y - P2.Y;
    ld r_s = dx * dx + dy * dy;
    ld r = sqrt(r_s);

    ld f = (G * P1.Mass * P2.Mass) / (r_s);
    return f;
}

void updateAcceleration(vector<Body> &bodies)
{
    vector<Body> copy_bodies = bodies;

    for (int i = 0; i < bodies.size(); ++i)
    {
        copy_bodies[i].Ax = 0;
        copy_bodies[i].Ay = 0;

        for (int j = 0; j < bodies.size(); ++j)
        {
            if (i != j)
            {
                ld f = abs_force(bodies[i], bodies[j]);
                ld a = f / bodies[i].Mass;
                ld dx = bodies[i].X - bodies[j].X;
                ld dy = bodies[i].Y - bodies[j].Y;
                ld r = sqrt(dx * dx + dy * dy);
                // if (r <= 0.001 && r >= -0.001)
                //     continue;
                
                copy_bodies[i].Ax += (-a * dx / r);
                copy_bodies[i].Ay += (-a * dy / r);
            }
        }
    }

    bodies = copy_bodies;
}

void updateVelocity(vector<Body> &bodies)
{
    for (int i = 0; i < bodies.size(); ++i)
    {
        bodies[i].Vx += bodies[i].Ax * dt;
        bodies[i].Vy += bodies[i].Ay * dt;
    }
}

void updatePosition(vector<Body> &bodies)
{
    for (int i = 0; i < bodies.size(); ++i)
    {
        bodies[i].X += bodies[i].Vx * dt + 0.5 * bodies[i].Ax * dt * dt;
        bodies[i].Y += bodies[i].Vy * dt + 0.5 * bodies[i].Ay * dt * dt;
    }
}

void write_body_data_to_file(const vector<Body> &bodies, ld time)
{
    // Write body data
    for (size_t i = 0; i < bodies.size(); ++i)
    {
        outFile << setw(15) << fixed << setprecision(6) << time << setw(15) << i + 1 << setw(15) << bodies[i].Mass << setw(15) << bodies[i].X << setw(15) << bodies[i].Y << setw(15) << bodies[i].Vx << setw(15) << bodies[i].Vy << setw(15) << bodies[i].Ax << setw(15) << bodies[i].Ay << endl;
    }
}

int main()
{
    // Open the file for appending
    if (!outFile.is_open())
    {
        cerr << "Error: Unable to open file for appending." << endl;
        return 0;
    }

    // Write header if the file is empty
    if (outFile.tellp() == 0)
    {
        outFile << setw(15) << "Time" << setw(15) << "Body" << setw(15) << "Mass" << setw(15) << "Sx" << setw(15) << "Sy" << setw(15) << "Ux" << setw(15) << "Uy" << setw(15) << "Ax" << setw(15) << "Ay" << endl;
    }

    int num_bodies;
    cout << "Enter the number of bodies: ";
    cin >> num_bodies;

    vector<Body> bodies;
    for (int i = 0; i < num_bodies; ++i)
    {
        ld mass, x, y, vx, vy, ax, ay;
        cout << "Enter mass, x, y, vx, vy, ax, ay for body " << i + 1 << ": ";
        cin >> mass >> x >> y >> vx >> vy >> ax >> ay;
        Body temp(mass, x, y, vx, vy, ax, ay);
        bodies.emplace_back(temp);
    }

    // Simulate the motion of the bodies
    for (int i = 0; i < 12000; ++i)
    {
        updateAcceleration(bodies);
        updateVelocity(bodies);
        updatePosition(bodies);

        write_body_data_to_file(bodies, dt * (i + 1));
    }

    // Close the file

    // plot graphs
    //system("python plot.py");

    // Execute the Python script with the number of bodies as argument
    string command = "python display.py " + to_string(num_bodies);
    system(command.c_str());

    std::ofstream outFile("data.txt", std::ofstream::trunc);
    outFile.close();

    return 0;
}
