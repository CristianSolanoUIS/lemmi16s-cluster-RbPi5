#!/usr/bin/env python3
"""
Copia de compute_f1_HM.py (misma logica de LEMMI: umbral de calibracion best_f1/max
y normalizacion GCN) para la instancia PacBio de 5 muestras que genero Cristian:
calibracion c001-c003, evaluacion e001-e002.

Usage: compute_f1_pacbio.py <WORK_DIR> <LABEL>
  WORK_DIR = benchmark/tmp/x86_energybench/lotus3_pacbio
  (contiene tmp_HM_Contaminated_Soil_PacBio-<muestra>/results.tsv)
"""
import sys
import numpy as np
import pandas as pd

pd.options.mode.chained_assignment = None

REPO = "/home/zamir/proyecto_grado/lemmi16s"
GCN_REF = f"{REPO}/benchmark/instances/HM_Contaminated_Soil_PacBio/referencia/GCN_ref.tsv"  # viene en el paquete de Cristian
GCN_NORMALIZATION = "yes"  # config["gcn_normalization"] == 1 for this instance
RANKS = ["family", "genus"]
FILTERING_STEP = 3

INSTANCES_DIR = f"{REPO}/benchmark/instances/HM_Contaminated_Soil_PacBio/muestras"
CALIBRATION_SAMPLES = ["HM_Contaminated_Soil-c001", "HM_Contaminated_Soil-c002", "HM_Contaminated_Soil-c003"]
EVALUATION_SAMPLES = ["HM_Contaminated_Soil-e001", "HM_Contaminated_Soil-e002"]


def GCN_reference(gnc_ref):
    gcn = pd.read_csv(str(gnc_ref), header=0, sep="\t")
    gcn = gcn[['taxid', 'name', 'mean']]
    gcn["mean"] = gcn["mean"].round().astype('int')
    gcn.columns = ['taxid', 'name', 'GCN_mean']
    return gcn


def getMax(row):
    maxGCN = 1
    for search in ["domain_GCN", "phylum_GCN", "class_GCN", "order_GCN", "family_GCN", "genus_GCN", "species_GCN"]:
        if row[search] > maxGCN:
            maxGCN = row[search]
    return maxGCN


def _load_reads_predictions(gcn, predictionFile, taxo, gcn_normalization):
    predictions_reads = pd.read_csv(predictionFile, header=1, sep="\t")
    df2 = predictions_reads['Taxonomy'].str.replace('; ', ';')
    df2 = df2.str.split(';', expand=True)
    df2.insert(0, "size", predictions_reads["Size"])
    df2.insert(0, "id", predictions_reads["Group_ID"])
    df2.columns = ['id', "size", "domain", "phylum", "class", "order", "family", "genus", "species"]
    df2.replace('Unassigned', 'na__Unassigned', inplace=True)
    df2.replace(np.nan, 'na__Unassigned', inplace=True)

    for search_tax_level in ["domain", "phylum", "class", "order", "family", "genus", "species"]:
        df = pd.DataFrame()
        df['id'] = df2[["id"]]
        df['name'] = df2[[search_tax_level]]
        df['name'] = df['name'].str.split('__').str.get(1)
        df['name'] = df['name'].str.replace('_', ' ')
        df = df.merge(gcn, how='left', on='name')
        df2[search_tax_level + '_GCN'] = df["GCN_mean"]
    df2.fillna(0, inplace=True)

    sumatory = {}
    gcn_value = {}
    for values in df2[taxo].unique():
        sumatory[values] = 0

    for index, row in df2.iterrows():
        values = row[taxo]
        reported_gcn = float(getMax(row)) if gcn_normalization == 'yes' else 1
        sumatory[values] = sumatory[values] + (row["size"] / reported_gcn)
        gcn_value[values] = reported_gcn

    df_tool_abud = pd.DataFrame([sumatory])
    df_tool_abud = df_tool_abud.T
    df_tool_abud.reset_index(inplace=True)
    df_tool_abud.columns = ['evaluation_taxa', 'reads']
    df_tool_abud['abundance'] = df_tool_abud['reads'] / df_tool_abud['reads'].sum()
    df_tool_abud['GCN_mean'] = df_tool_abud['evaluation_taxa'].map(gcn_value)
    return df_tool_abud


def load_predictions(gcn, predictionFile, taxo, gcn_normalization):
    return _load_reads_predictions(gcn, predictionFile, taxo, gcn_normalization)


def load_truth(gcn, predictionFile, taxo, gcn_normalization):
    return _load_reads_predictions(gcn, predictionFile, taxo, gcn_normalization)


def evaluation_results(predictions, truth, threshold):
    predictions = predictions[predictions["reads"] >= threshold]
    if len(predictions) == 0:
        return predictions
    if len(truth) == 0:
        return predictions
    predictions.loc[:, "evaluation"] = predictions.apply(
        lambda row: row["evaluation_taxa"] in truth["evaluation_taxa"].values,
        axis=1,
    )
    return predictions


def get_precision(predictions, truth, threshold):
    try:
        predictions = evaluation_results(predictions, truth, threshold)
        precision = predictions[predictions["evaluation"]].evaluation.count() / predictions["evaluation"].count()
        if precision >= 0:
            return precision
        return 0
    except (KeyError, ZeroDivisionError):
        return 0


def get_recall(predictions, truth, threshold):
    try:
        predictions = evaluation_results(predictions, truth, threshold)
        recall = predictions[predictions["evaluation"]].evaluation.count() / truth["evaluation_taxa"].count()
        return recall
    except (KeyError, ZeroDivisionError):
        return 0


def get_f1(predictions, truth, threshold):
    try:
        predictions = evaluation_results(predictions, truth, threshold)
        precision = predictions[predictions["evaluation"]].evaluation.count() / predictions["evaluation"].count()
        recall = predictions[predictions["evaluation"]].evaluation.count() / truth["evaluation_taxa"].count()
        f1 = 2 * (precision * recall) / (precision + recall)
        if f1 >= 0:
            return f1
        return 0
    except (KeyError, ZeroDivisionError):
        return 0


def main():
    if len(sys.argv) != 3:
        print("Usage: compute_f1_pacbio.py <WORK_DIR> <LABEL>")
        sys.exit(1)
    WORK, LABEL = sys.argv[1], sys.argv[2]

    gcn = GCN_reference(GCN_REF)

    results = {}
    for rank in RANKS:
        thresholds = []
        for csample in CALIBRATION_SAMPLES:
            pred_file = f"{WORK}/tmp_{csample.replace('Soil-', 'Soil_PacBio-')}/results.tsv"
            truth_file = f"{INSTANCES_DIR}/{csample}/queryTaxo.tsv"

            predictions = load_predictions(gcn, pred_file, rank, GCN_NORMALIZATION)
            truth = load_truth(gcn, truth_file, rank, GCN_NORMALIZATION)

            threshold = 0
            best_f1 = 0
            best_threshold = -1
            while True:
                precision = get_precision(predictions, truth, threshold)
                recall = get_recall(predictions, truth, threshold)
                f1 = get_f1(predictions, truth, threshold)
                if f1 > best_f1:
                    best_f1 = f1
                    best_threshold = threshold
                if precision == 1:
                    break
                if recall == 0:
                    break
                threshold += FILTERING_STEP
            thresholds.append(best_threshold)

        filtering_threshold = max(thresholds)

        f1_values = []
        for esample in EVALUATION_SAMPLES:
            pred_file = f"{WORK}/tmp_{esample.replace('Soil-', 'Soil_PacBio-')}/results.tsv"
            truth_file = f"{INSTANCES_DIR}/{esample}/queryTaxo.tsv"

            predictions = load_predictions(gcn, pred_file, rank, GCN_NORMALIZATION)
            truth = load_truth(gcn, truth_file, rank, GCN_NORMALIZATION)

            f1 = get_f1(predictions, truth, filtering_threshold)
            f1_values.append(f1)
            print(f"[{LABEL}][{rank}] sample={esample} threshold={filtering_threshold} f1={f1}")

        results[rank] = {
            "calibration_thresholds": thresholds,
            "filtering_threshold": filtering_threshold,
            "f1_per_eval_sample": f1_values,
            "f1_mean": float(np.mean(f1_values)),
        }

    print(f"\n=== SUMMARY [{LABEL}] ===")
    for rank in RANKS:
        print(rank, results[rank])


if __name__ == "__main__":
    main()
