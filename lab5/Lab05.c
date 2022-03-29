//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Parallel Computing and System Lab
//   All Right Reserved ???
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2020 Fall SoftWare
//   Lab05 Exercise		: Matrix Computation
//   Author     		: ABC
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : Lab05.c
//   Release version : V1.0 (Release Date: 2020-10-22 AM 11:35:34)
//   Note1 : ALL random values are positive
//   Note2 : no overflow version
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PATNUM 10

///Function
void Generate_Matrix();
void Convolution(int);
void MaxPooling(int);
void ReLU(int);
void FullyConnected(int);
int  Find_Max(int, int, int, int);
void Show_Output(int);
void error();

///Golbal variables
int Matrix[16][16];
int Matrix_Size;
int act_times;
FILE *in;
FILE *out;

int main()
{

    in = fopen("input.txt", "w");
    out = fopen("output.txt", "w");
    //int act_times;
    for (int i = 0; i < PATNUM; i++)
    {

        act_times = rand() % 20 + 1;
        Generate_Matrix();
        Show_Output(Matrix_Size);
        for (int j = 0; j < act_times; j++)
        {
            int act = rand() % 4;
            if (Matrix_Size == 2 && act == 2)
            {
                j--;
                continue;
            }
            fprintf(in, "\n%d\n", act);
            switch (act)
            {
            case 0:
                Convolution(Matrix_Size);
                break;
            case 1:
                ReLU(Matrix_Size);
                break;
            case 2:
                MaxPooling(Matrix_Size);
                break;
            case 3:
                FullyConnected(Matrix_Size);
                break;
            default:
                error();
            }
            Show_Output(Matrix_Size);
        }
        fprintf(in, "\n\n\n\n\n");
        fprintf(out, "\n\n\n\n\n");
    }
    fclose(in);
    printf("\nFinish\n");
}

void Generate_Matrix()
{
    int size[4] = {16, 8, 4, 2};
    int rand_size = rand() % 4;
    Matrix_Size = size[rand_size];
    fprintf(in, "%d\n", rand_size);
    fprintf(in, "%d\n", act_times);
    for (int i = 0; i < Matrix_Size; i++)
    {
        for (int j = 0; j < Matrix_Size; j++)
        {
            Matrix[i][j] = rand() % 100;
            fprintf(in, "%d ", Matrix[i][j]);
        }
        fprintf(in, "\n");
    }
}

void Convolution(int size)
{
    int kernal[9];
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            kernal[i * 3 + j] = rand() % 10;
            fprintf(in, "%d ", kernal[i * 3 + j]);
        }

        fprintf(in, "\n");
    }
    int tmp[65][65];
    memset(tmp, 0, sizeof(int) * 65 * 65);

    ///zero padding
    for (int i = 1; i < size; i++)
        for (int j = 1; j < size; j++)
            tmp[i][j] = Matrix[i][j];

    for (int i = 0; i < size; i++)
    {
        for (int j = 0; j < size; j++)
        {
            int value = 0;
            int ha = 0;
            for (int k = i; k < i + 3; k++)
            {
                for (int l = j; l < j + 3; l++)
                {
                    value += tmp[k][l] * kernal[ha]; /* code */
                    ha++;
                }
            }
            Matrix[i][j] = value;
        }
    }
}

void ReLU(int size)
{
    for (int i = 0; i < size; i++)
        for (int j = 0; j < size; j++)
            Matrix[i][j] = (Matrix[i][j] > 0) ? Matrix[i][j] : 0;
}

void MaxPooling(int size)
{
    for (int i = 0; i < size; i += 2)
    {
        for (int j = 0; j < size; j += 2)
        {
            int max = Find_Max(Matrix[i][j], Matrix[i][j + 1], Matrix[i + 1][j], Matrix[i + 1][j + 1]);
            Matrix[i / 2][j / 2] = max;
        }
    }
    Matrix_Size = Matrix_Size / 2;
}

int Find_Max(int a, int b, int c, int d)
{
    int max0 = (a > b) ? a : b;
    int max1 = (c > d) ? c : d;
    int max = (max0 > max1) ? max0 : max1;
    return max;
}

void FullyConnected(int size)
{
    int Wsize = size * size;
    fprintf(in, "%d\n", size);
    int weight[256][256];
    int k, z;
    for (k = 0; k < Wsize; k++)
    {
        for (z = 0; z < Wsize; z++)
        {
            weight[k][z] = rand() % 10;
            fprintf(in, "%d ", weight[k][z]);
        }
        fprintf(in, "\n");
    }

    int tmp[256];
    for (int i = 0; i < Wsize; i++)
    {
        tmp[i] = Matrix[i / 16][i % 16];
    }
    for (int i = 0; i < Wsize; i++)
    {
        int val = 0;
        for (int j = 0; j < Wsize; j++)
        {
            val += weight[i][j] * tmp[j];
        }

        Matrix[i / 16][i % 16] = val;
    }
}

void Show_Output(int size)
{
    int i, j;
    fprintf(out,"%d\n",Matrix_Size*Matrix_Size);
    for (i = 0; i < size; i++)
    {
        for (j = 0; j < size;j++)
        {
            fprintf(out, "%d ", Matrix[i][j]);
        }
        fprintf(out, "\n");
    }
}

void error()
{
    printf("QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ");
}
