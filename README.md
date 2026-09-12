# GRASS GIS Scripts — Machine-Learning Land-Cover Classification of Landsat over Eritrea

GRASS GIS shell scripts used to produce the figures in the peer-reviewed article by Polina Lemenkova. The scripts classify a Landsat 8-9 OLI/TIRS time series (2014, 2018, 2022, 2024) over the coastal and desert areas of Eritrea around the Massawa Channel and Semenawi Bahri National Park, comparing several machine-learning classifiers against traditional maximum-likelihood clustering.

**Published in:** *Engineering TODAY* **2025**, *4*(2), 13–27
**DOI:** https://doi.org/10.5937/engtoday2500008L
**Journal (open access):** https://www.engineering-today.com/index.php/et/article/view/117

## Contents
Shell scripts calling GRASS GIS modules for raster import (r.import), colour composites (r.composite), contouring (r.contour) over a GEBCO shaded relief, clustering and classification (i.group, i.cluster k-means, i.maxlik maximum-likelihood), training-sample generation (r.random) and machine-learning classification (r.learn.train, r.learn.predict) with Linear Discriminant Analysis (LDA), Gaussian Naive Bayes (GNB), Decision Tree (DTC) and Support Vector Machine (SVM) classifiers from Python's Scikit-Learn library. One script and one cluster report per year (2014, 2018, 2022, 2024).

## LaTeX source
The LaTeX source (prose) of this article is in a separate repository: https://github.com/paulinelemenkova/ml-image-classification-optimization-eritrea

## Citation
Lemenkova, P. Machine learning algorithms for optimization of image classification in spatially constrained regions: A case of Eritrea, East Africa. *Engineering TODAY* **2025**, *4*(2), 13–27. https://doi.org/10.5937/engtoday2500008L
