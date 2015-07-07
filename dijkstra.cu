#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define INF INT_MAX
#define NUMBEROFVERTICES 501
#define NUMBEROFEDGES 998

int Ma_notEmpty(int *);

int Ma_notEmpty(int *Ma)
{
	int i, sum = 0;
	for(i=0; i <  NUMBEROFVERTICES; i++)
	{
		sum += Ma[i];
	}
	return sum;
}




__global__ void CUDA_SSSP_KERNEL1(int *Va, int *Ea, int *Wa, int *Ca, int *Ma, int *Ua)
{
	int tid = blockDim.x * blockIdx.x + threadIdx.x;
	int nid, i;


	if(Ma[tid])
	{
		Ma[tid] = 0;
		for (i = Va[tid]; i < Va[tid+1]; i++)
		{
			nid = Ea[i];
			if (Ua[nid] > Ca[tid] + Wa[nid])
			{
				Ua[nid] = Ca[tid] + Wa[nid];
			}
		}
	}
	
}

__global__ void CUDA_SSSP_KERNEL2(int *Va, int *Ea, int *Wa, int *Ca, int *Ma, int *Ua)
{
	int tid = blockDim.x * blockIdx.x + threadIdx.x;
	if(Ca[tid] > Ua[tid])
	{
		Ca[tid] = Ua[tid];
		Ma[tid] = 1;
	}
	Ua[tid] = Ca[tid];
}

int main(int argc, char **argv)
{
	cudaEvent_t begin, end;
	cudaEventCreate(&begin);
	cudaEventCreate(&end);
	float millisecond = 0;
	int adjacency_matrix[NUMBEROFVERTICES][NUMBEROFVERTICES];
	int  j;
	int sum = 0, e = 0;
	
	int S = 0, i;

	int h_Va[NUMBEROFVERTICES];
	int h_Ea[NUMBEROFEDGES];
	int h_Wa[NUMBEROFEDGES];
	
	int h_Ca[NUMBEROFVERTICES];
	int h_Ma[NUMBEROFVERTICES];
	int h_Ua[NUMBEROFVERTICES];

	int V_BYTESIZE = NUMBEROFVERTICES * sizeof(int);
	int E_BYTESIZE = NUMBEROFEDGES * sizeof(int);

	int *d_Va, *d_Ea, *d_Wa, *d_Ca, *d_Ma, *d_Ua;
	srand(time(NULL));

	for (i=0; i < NUMBEROFVERTICES; i++)
	{
		h_Ca[i] = INF;
		h_Ma[i] = 0;
		h_Ua[i] = INF;
	}

//==================================================================
/*memset(adjacency_matrix, 0, sizeof(int) * NUMBEROFVERTICES * NUMBEROFVERTICES);
for (i = 0; i < NUMBEROFVERTICES -1; i++)
{
	for (j = 0; j < NUMBEROFVERTICES -1; j++)
	{
		if (j == (i + 1) || i == (j + 1))
			adjacency_matrix[i][j] = 1;
		else
			adjacency_matrix[i][j] = 0;
	}

}

adjacency_matrix[NUMBEROFVERTICES -2][NUMBEROFVERTICES -2] = 1;*/
//==================================================================
	memset(adjacency_matrix, 0, sizeof(int) * NUMBEROFVERTICES * NUMBEROFVERTICES);
	for(i = 0; i < NUMBEROFVERTICES -1; i++)
	{
		for(j = 0; j < NUMBEROFVERTICES -1; j++)
		{
			if(j == (2 * i + 1) || i == (2 * j + 1))
				adjacency_matrix[i][j] = 1;
			else if(j == (2 * i + 2) || i == (2 * j + 2))
				adjacency_matrix[i][j] = 1;
		}
	}
 

	

	for (i = 0; i < NUMBEROFVERTICES-1; i++)
	{
		h_Va[i] = sum;
		for (j = 0; j < NUMBEROFVERTICES-1; j++)
		{
			if (adjacency_matrix[i][j] == 1)
			{
				h_Ea[e++] = j;
			}
			sum += adjacency_matrix[i][j];	 
		}
	}

	for (i=0; i < NUMBEROFEDGES; i++)
	{
		//h_Wa[i] = 1;
		h_Wa[i] = (rand() % 10) + 1;
	}

	/*for (i = 0; i < NUMBEROFVERTICES; i++)
	{
		printf("V[%d]= %d \t", i, h_Va[i]);
	}
	printf("\n");
	
	for (i = 0; i < NUMBEROFEDGES; i++)
	{
		printf("E[%d]= %d \tW[%d]= %d", i, h_Ea[i], i, h_Wa[i]);
	}*/
//==================================================================	
//	createTree(h_Va, h_Ea);	
	/*h_Va[0] = 0;
	h_Va[1] = 3;
	h_Va[2] = 5;
	h_Va[3] = 7;
	h_Va[4] = 8;
	h_Va[5] = 10;
	h_Va[6] = 12;
	

	h_Ea[0] = 1;
	h_Ea[1] = 2;
	h_Ea[2] = 3;
	h_Ea[3] = 0;
	h_Ea[4] = 5;
	h_Ea[5] = 0;
	h_Ea[6] = 4;
	h_Ea[7] = 0;
	h_Ea[8] = 2;
	h_Ea[9] = 5;
	h_Ea[10] = 1;
	h_Ea[11] = 4;
	

	h_Wa[0] = 1;
	h_Wa[1] = 1;
	h_Wa[2] = 1;
	h_Wa[3] = 1;
	h_Wa[4] = 1;
	h_Wa[5] = 1;
	h_Wa[6] = 1;
	h_Wa[7] = 1;
	h_Wa[8] = 1;
	h_Wa[9] = 1;
	h_Wa[10] = 1;
	h_Wa[11] = 1;*/
	
	
	cudaMalloc((void **) &d_Va, V_BYTESIZE);
	cudaMalloc((void **) &d_Ea, E_BYTESIZE);
	cudaMalloc((void **) &d_Wa, E_BYTESIZE);
	cudaMalloc((void **) &d_Ca, V_BYTESIZE);
	cudaMalloc((void **) &d_Ma, V_BYTESIZE);
	cudaMalloc((void **) &d_Ua, V_BYTESIZE);

	cudaMemcpy(d_Va, h_Va, V_BYTESIZE, cudaMemcpyHostToDevice);
	cudaMemcpy(d_Ea, h_Ea, E_BYTESIZE, cudaMemcpyHostToDevice);
	cudaMemcpy(d_Wa, h_Wa, E_BYTESIZE, cudaMemcpyHostToDevice);
	cudaMemcpy(d_Ma, h_Ma, V_BYTESIZE, cudaMemcpyHostToDevice);
	h_Ma[S] = 1;
	h_Ca[S] = 0;
	h_Ua[S] = 0;
	
	cudaEventRecord(begin);
	while(Ma_notEmpty(h_Ma))
	{
		cudaMemcpy(d_Ca, h_Ca, V_BYTESIZE, cudaMemcpyHostToDevice);
		cudaMemcpy(d_Ua, h_Ua, V_BYTESIZE, cudaMemcpyHostToDevice);
		cudaMemcpy(d_Ma, h_Ma, V_BYTESIZE, cudaMemcpyHostToDevice);

		CUDA_SSSP_KERNEL1<<<1, (NUMBEROFVERTICES-1)>>>(d_Va, d_Ea, d_Wa, d_Ca, d_Ma, d_Ua);

		cudaMemcpy(h_Ca, d_Ca, V_BYTESIZE, cudaMemcpyDeviceToHost);
		cudaMemcpy(h_Ua, d_Ua, V_BYTESIZE, cudaMemcpyDeviceToHost);
		cudaMemcpy(h_Ma, d_Ma, V_BYTESIZE, cudaMemcpyDeviceToHost);
		cudaMemcpy(d_Ca, h_Ca, V_BYTESIZE, cudaMemcpyHostToDevice);
		cudaMemcpy(d_Ua, h_Ua, V_BYTESIZE, cudaMemcpyHostToDevice);
		cudaMemcpy(d_Ma, h_Ma, V_BYTESIZE, cudaMemcpyHostToDevice);		


		CUDA_SSSP_KERNEL2<<<1, (NUMBEROFVERTICES-1)>>>(d_Va, d_Ea, d_Wa, d_Ca, d_Ma, d_Ua);
		//printf("_____________________________\n");

		cudaMemcpy(h_Ma, d_Ma, V_BYTESIZE, cudaMemcpyDeviceToHost);
		cudaMemcpy(h_Ca, d_Ca, V_BYTESIZE, cudaMemcpyDeviceToHost);
		cudaMemcpy(h_Ua, d_Ua, V_BYTESIZE, cudaMemcpyDeviceToHost);
		cudaMemcpy(d_Ca, h_Ca, V_BYTESIZE, cudaMemcpyHostToDevice);
		cudaMemcpy(d_Ma, h_Ma, V_BYTESIZE, cudaMemcpyHostToDevice);
		cudaMemcpy(d_Ua, h_Ua, V_BYTESIZE, cudaMemcpyHostToDevice);

		/*for(i=0; i < NUMBEROFVERTICES; i++)
		{
			printf("Ma[%d]  Ua[%d] Ca[%d]\n",h_Ma[i], h_Ua[i], h_Ca[i]);
		}
		printf("_____________________________\n");*/
//		break;
	}

	cudaMemcpy(d_Ca, h_Ca, V_BYTESIZE, cudaMemcpyHostToDevice);
	cudaMemcpy(d_Ma, h_Ma, V_BYTESIZE, cudaMemcpyHostToDevice);
	cudaMemcpy(d_Ua, h_Ua, V_BYTESIZE, cudaMemcpyHostToDevice);
	/* print result */
	cudaEventRecord(end);
	cudaEventSynchronize(end);
	cudaEventElapsedTime(&millisecond, begin, end);
	for(i=0; i < NUMBEROFVERTICES - 1; i++)
	{
		printf("[%d]\t", h_Ca[i]);
	}

	printf("\n >> mSecond= %f\n", millisecond);

	cudaFree(d_Ca);
	cudaFree(d_Ma);
	cudaFree(d_Ua);
	cudaFree(d_Va);
	cudaFree(d_Ea);
	cudaFree(d_Wa);

	return EXIT_SUCCESS;
}
