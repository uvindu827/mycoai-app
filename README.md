# 🍄 Mushroom Identifier

> An AI-powered mobile application designed to identify mushroom species instantly using your smartphone camera.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![TensorFlow](https://img.shields.io/badge/TensorFlow-%23FF6F00.svg?style=for-the-badge&logo=TensorFlow&logoColor=white)

## 📱 Project Overview

This project combines Computer Vision and Mobile Development to help users identify mushrooms in the wild. It consists of two main components:
1.  **Flutter Mobile App:** A cross-platform application for iOS and Android that handles the user interface and camera inputs.
2.  **Machine Learning Model:** A Python-based notebook used to train, validate, and export the image classification model.

## 📸 Screenshots

| Home Screen | Camera View | Prediction Result |
|:---:|:---:|:---:|
| <img src="path/to/screenshot1.png" width="200"> | <img src="path/to/screenshot2.png" width="200"> | <img src="path/to/screenshot3.png" width="200"> |

## 📂 Repository Structure

This repository is organized into two distinct sections:

```bash
├── mushroom_app/        # The Flutter application source code
│   ├── lib/             # UI and Logic
│   └── pubspec.yaml     # Dependencies
│
├── model_notebooks/     # Data Science work
│   └── training.ipynb   # Model training and evaluation
│
└── README.md            # You are here
