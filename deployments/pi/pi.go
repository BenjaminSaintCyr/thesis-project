package main

import (
	"fmt"
	"math/rand"
	"net/http"
	"runtime"
	"strconv"
	"time"
)

func MultiPI(samples int) float64 {
	cpus := runtime.NumCPU()

	threadSamples := samples / cpus
	results := make(chan float64, cpus)

	for j := 0; j < cpus; j++ {
		go func() {
			var inside int
			r := rand.New(rand.NewSource(time.Now().UnixNano()))
			for i := 0; i < threadSamples; i++ {
				x, y := r.Float64(), r.Float64()

				if x*x+y*y <= 1 {
					inside++
				}
			}
			results <- float64(inside) / float64(threadSamples) * 4
		}()
	}

	var total float64
	for i := 0; i < cpus; i++ {
		total += <-results
	}

	return total / float64(cpus)
}

func handlePI(w http.ResponseWriter, r *http.Request) {
	samples := r.URL.Query().Get("samples")
	if samples == "" {
		http.Error(w, "Missing 'samples' parameter in query string", http.StatusBadRequest)
		return
	}

	samplesInt, err := strconv.Atoi(samples)
	if err != nil {
		http.Error(w, "'samples' parameter must be a valid integer", http.StatusBadRequest)
		return
	}

	pi := MultiPI(samplesInt)

	fmt.Fprintf(w, "Estimated value of Pi: %f", pi)
}

func main() {
	http.HandleFunc("/", handlePI)

	fmt.Println("Server running on port 8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		fmt.Println(err)
		return
	}
}

