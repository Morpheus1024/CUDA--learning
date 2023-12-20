#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <stdlib.h>
#include <cstdint>
#define BLOCK_SIZE 16
typedef struct
{
int width;
int height;
float* dataArray;
int dataArraySize;
} Data;
__global__ void VecAdd(Data dim_gpu, float* values_gpu) {
const int index = threadIdx.x + blockIdx.x * blockDim.x;
if (index < dim_gpu.dataArraySize) {
values_gpu[index] = dim_gpu.dataArray[index] + 100.0;
}
}
int main()
{
constexpr int rgb_size = 3;
Data dim{};
dim.width = 400* rgb_size;
dim.height = 400;
dim.dataArraySize = dim.width * dim.height * rgb_size;
dim.dataArray = new float[dim.dataArraySize];
float mem_size = dim.width * dim.height * rgb_size * sizeof(float);
for (int i = 0; i < dim.dataArraySize; i++)
{
dim.dataArray[i] = float((rand() % 100) * 1.59); // random as: 0-99 * 1.59
if (i % 48000 == 0) {
printf("%.3f\n", dim.dataArray[i]);
}
}
// tutaj chcemy zwracać wartości, więc potrzeba nam pamięci po cpu i gpu
float* values_cpu = new float[dim.dataArraySize];
float* values_gpu;
cudaMalloc(&values_gpu, mem_size);
Data dim_gpu{};
dim_gpu.width = dim.width;
dim_gpu.height = dim.height;
dim_gpu.dataArraySize = dim.dataArraySize;
cudaMalloc(&dim_gpu.dataArray, mem_size);
cudaMemcpy(dim_gpu.dataArray, dim.dataArray, mem_size, cudaMemcpyHostToDevice);
int threadsPerBlock = 256;
int blocksPerGrid =
(dim.dataArraySize + threadsPerBlock - 1) / threadsPerBlock;
VecAdd <<<blocksPerGrid, threadsPerBlock >>> (dim_gpu, values_gpu);
cudaMemcpy(values_cpu, values_gpu, mem_size, cudaMemcpyDeviceToHost);
for (int i = 0; i < dim.dataArraySize; i++)
{
if (i % 48000 == 0 ) {
printf("%.3f %.3f\n", (dim.dataArray[i] + 100.0), values_cpu[i]);
}
}
cudaError_t error = cudaGetLastError();
if (error != cudaSuccess)
{
fprintf(stderr, "ERROR: %s\n", cudaGetErrorString(error));
exit(-1);
}
//zwracamy pamięć
delete(dim.dataArray);
delete(values_cpu);
cudaFree(dim_gpu.dataArray);
cudaFree(values_gpu);
return 0;
}S
