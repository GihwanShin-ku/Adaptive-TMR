# Adaptive Targeted Memory Reactivation

This repository contains the scripts associated with the manuscript:

**"Adaptive targeted memory reactivation enhances learning and consolidation for challenging memories via slow-wave spindle dynamics."**

## Code Structure
The repository is organized into the following main directories:

- **Behavior**: Contains scripts related to behavioral data analysis, including:
  - **Questionnaires**: Analysis of participant responses to surveys.
  - **Accuracy**: Calculation of performance metrics such as correct responses.
  - **Transition**: Analysis of transitions between correct and incorrect responses, etc.

- **Experiment**: Includes scripts for setting up and running the experimental protocols, as well as data collection.

- **Sleep**: Contains scripts for EEG data analysis, including:
  - **Parameters**: Sleep architecture.
  - **Hypnogram**: Visualization of sleep stages.
  - **Merge**: Combining data from multiple sessions or subjects.
  - **Preprocessing (PP)**: Data cleaning and preparation.
  - **ERP**: Event-related potential analysis.
  - **TFR**: Time-frequency representation analysis.
  - **ERPAC**: Phase-amplitude coupling analysis.
  - **Correlation**: Correlation between behavior and EEG features.
  - **Classification**: Machine learning-based classification of EEG features.
  - **PTE**: Phase transfer entropy analysis, etc.

## Usage
### Prerequisites
Ensure you have the following dependencies installed:
- MATLAB R2023b or later
  - Required toolbox: EEGLAB ([Download here](https://sccn.ucsd.edu/eeglab/download.php))
- Python 3.12 or later
  - Required Python packages: `numpy`, `os`, `scipy`, `tensorpac`

### Steps to Run
1. Clone this repository:
   ```bash
   git clone https://github.com/GihwanShin-ku/adaptive-tmr.git
   cd adaptive-tmr
   ```

2. Download EEG and behavioral data from [Open Science Framework (OSF)](https://osf.io/3g8rm).

3. Perform **Behavior** analysis using the following scripts:
   - `Accuracy`: Calculate accuracy metrics.
   - `Accuracy_plot`: Visualize accuracy results.
   - `Accuracy_level_plot`: Plot accuracy across levels.
   - `Transition`: Analyze transitions between correct and incorrect responses.

4. Perform **Sleep** analysis in the following order:
   - `Merge`: Combine multiple sessions or subject data.
   - `PP`: Preprocess EEG data.
   - `ERP_calc_Adaptive_TMR`: Calculate ERP for Adaptive TMR.
   - `ERP_calc_TMR`: Calculate ERP for TMR.
   - `ERP_calc_CNT`: Calculate ERP for Control group (CNT).
   - `TFR_calc`: Perform time-frequency representation calculation.
   - `TFR_plot`: Plot time-frequency representation results.
   - `ERPAC_calc`: Calculate phase-amplitude coupling.
   - `ERPAC_plot`: Visualize phase-amplitude coupling.
   - `TFR_plot_power`: Plot TFR power.
   - `ERPAC_plot_power`: Plot ERPAC power.
   - `Correlation`: Analyze correlations between behavior and EEG features.
   - `Classification_SW`: Classify using slow wave data.
   - `Classification_SS`: Classify using sleep spindle data.
   - `Classification_SWSS`: Classify using slow wave and sleep spindle data.
   - `Classification_plot`: Visualize classification results.
   - `PRES`: Perform PRES analysis.
   - `PTE_calc`: Calculate phase transfer entropy.
   - `PTE_plot`: Plot phase transfer entropy results.

## Contact
For questions or comments, please contact gh_shin@korea.ac.kr.
