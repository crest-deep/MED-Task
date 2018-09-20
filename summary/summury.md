# MED Simple Summary

There are two steps (feature extraction and score calculation) in current MED system.

## Feature Extraction

In this step, the system extracts feature vectors from videos.
Frame images are extracted from inputed videos internally so it is not necessary to extract frames manually.

Input: Video
Output Feature Vector

An architecture of CNN model and a dataset used to train a model is switchable.

### Architecture

- GoogLeNet (baseline)
- ResNext

### Dataset

- ImageNetShuffle Bottom-up 12,988 (baseline)

## Score Calculation

In this step, the system calculates scores from feature vectors.

Input: Feature Vector
Output: Score Value

There are two methods currently.

### Method

- SVM (baseline)
- LSTM
