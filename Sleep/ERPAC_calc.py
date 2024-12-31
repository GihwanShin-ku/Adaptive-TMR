import os
import numpy as np
from scipy.io import loadmat, savemat
from tensorpac import EventRelatedPac

# %% Path Setting
temp = os.getcwd()
list_path = temp.split(os.sep)
path_base = os.sep.join(list_path[:-2]) + os.sep
path = os.path.join(path_base, 'Analysis', 'Sleep', 'ERP') + os.sep
path_save = os.path.join(path_base, 'Analysis', 'Sleep', 'ERPAC') + os.sep # circular

print("Base Path: ", path_base)
print("Analysis Path: ", path)
print("Save Path: ", path_save)

# %% ERPAC Analysis
fs = 100  
f_pha_range = [1, 4]  
f_amp_range = np.arange(4, 20.5, 0.5)

p = EventRelatedPac(f_pha=f_pha_range, f_amp=f_amp_range)

def calculate_erpac(data, level=None):
    if level is not None:
        level = level.astype(int)

        all_data = data
        l3_data = data[:, :, level == 3]
        datasets = [all_data, l3_data]
        result_names = ['ALL', 'L3']
    else:
        datasets = [data]
        result_names = ['ALL']

    erpac_results = {}
    
    for i, dataset in enumerate(datasets):
        channels, timepoints, trials = dataset.shape
        result = None  
        
        # circular, gc
        for ch1 in range(channels):
            for ch2 in range(channels):
                pha = p.filter(fs, dataset[ch1, :, :].T, ftype='phase', n_jobs=1)  
                amp = p.filter(fs, dataset[ch2, :, :].T, ftype='amplitude', n_jobs=1)  
                erpac = p.fit(pha, amp, method='circular', smooth=20, n_jobs=-1).squeeze()
                
                if result is None:
                    result = np.zeros((channels, channels, erpac.shape[0], timepoints))
                
                result[ch1, ch2, :, :] = erpac  

        # save
        erpac_results[result_names[i]] = result

    return erpac_results

groups = ['Adaptive_TMR', 'TMR', 'CNT'] # 'Adaptive_TMR', 'TMR', CNT'

for group in groups:
    group_path = os.path.join(path, group)
    save_group_path = os.path.join(path_save, group)

    if not os.path.exists(save_group_path):
        os.makedirs(save_group_path)

    subjects = [f for f in os.listdir(group_path) if f.endswith('.mat')]

    for subject in subjects:
        mat_file_path = os.path.join(group_path, subject)
        loaded_data = loadmat(mat_file_path)

        save_path = os.path.join(save_group_path, subject)

        if 'Adaptive_TMR_PAC' in loaded_data:
            level = loaded_data['Level'].squeeze()
            data = loaded_data['Adaptive_TMR_PAC']
            results = calculate_erpac(data, level)
            savemat(save_path, results)

        if 'TMR_PAC' in loaded_data:
            level = loaded_data['Level'].squeeze()
            data = loaded_data['TMR_PAC']
            results = calculate_erpac(data, level)
            savemat(save_path, results)

        if 'CNT_PAC' in loaded_data:
            data = loaded_data['CNT_PAC']
            results = calculate_erpac(data)
            savemat(save_path, results)

        print(f"Group: {group}, Subject: {subject} Done!")

print("ERPAC Analysis Completed and Results Saved.")

