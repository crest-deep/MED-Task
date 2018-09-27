## Analysis of improvement
#### Feature
- Speed: Faster GPU speed + more GPU parallelism (10.53X)
- Storage: Combine frame extraction and feature extraction (39.4X)

#### LSTM training speed :
- Fewer epochs required to converge due to adopting larger batch (100 epochs -> 40 epochs, 2.5X)
- Less time required to run one epoch due to
    - Faster GPU speed and better parallelism for larger batch (9.8X)
    - Code optimization including applying asynchronous data copying and avoiding unnecessary data copying (1.15X)

#### LSTM testing speed :
- Faster GPU speed + more GPU parallelism (12.18X)
- Code optimization including applying asynchronous data copying and avoiding unnecessary data copying (1.20X)