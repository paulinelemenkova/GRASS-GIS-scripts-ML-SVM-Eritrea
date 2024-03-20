#!/bin/sh

grass

# ----IMPORT AND PREPROCESSING-------------------------->

# importing the image subset with 7 Landsat bands and display the raster map
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20240309_20240316_02_T1_SR_B1.TIF output=L_2024_01 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20240309_20240316_02_T1_SR_B2.TIF output=L_2024_02 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20240309_20240316_02_T1_SR_B3.TIF output=L_2024_03 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20240309_20240316_02_T1_SR_B4.TIF output=L_2024_04 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20240309_20240316_02_T1_SR_B5.TIF output=L_2024_05 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20240309_20240316_02_T1_SR_B6.TIF output=L_2024_06 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20240309_20240316_02_T1_SR_B7.TIF output=L_2024_07 extent=region resolution=region
#
g.list rast
# shaded relief
r.import input=/Users/polinalemenkova/grassdata/Eritrea/gebco_2023.tif output=shaded_relief extent=region --overwrite
r.contour shaded_relief out=isolines step=200 --overwrite
#
g.list rast

# ---CREATING COLOR COMPOSITES------------------->
#
r.composite blue=L_2024_07 green=L_2024_05 red=L_2024_04 output=L_2024_754 --overwrite
d.mon wx0
d.rast L_2024_754
d.out.file output=Eritrea_754 format=jpg --overwrite
#
r.composite blue=L_2024_01 green=L_2024_02 red=L_2024_03 output=L_2024_123 --overwrite
d.mon wx0
d.rast L_2024_123
d.out.file output=Eritrea_2024_123 format=jpg --overwrite
#
r.composite blue=L_2024_03 green=L_2024_04 red=L_2024_05 output=L_2024_345 --overwrite
d.mon wx0
d.rast L_2024_345
d.out.file output=Eritrea_2024_345 format=jpg --overwrite
#
r.composite blue=L_2024_01 green=L_2024_05 red=L_2024_06 output=L_2024_156 --overwrite
d.mon wx0
d.rast L_2024_156
d.out.file output=Eritrea_2024_156 format=jpg --overwrite
#
r.composite blue=L_2024_01 green=L_2024_04 red=L_2024_06 output=L_2024_146 --overwrite
d.mon wx0
d.rast L_2024_146
d.out.file output=Eritrea_2024_146 format=jpg --overwrite
#
r.composite blue=L_2024_05 green=L_2024_04 red=L_2024_03 output=L_2024_543 --overwrite
d.mon wx0
d.rast L_2024_543
d.out.file output=Eritrea_2024_543 format=jpg --overwrite
#
r.composite blue=L_2024_06 green=L_2024_04 red=L_2024_02 output=L_2024_642 --overwrite
d.mon wx0
d.rast L_2024_642
d.out.file output=Eritrea_2024_642 format=jpg --overwrite

# ---CLUSTERING AND CLASSIFICATION------------------->
# Set computational region to match the scene
g.region raster=L_2024_01 -p
# grouping data by i.group
i.group group=L_2024 subgroup=res_30m \
  input=L_2024_01,L_2024_02,L_2024_03,L_2024_04,L_2024_05,L_2024_06,L_2024_07 --overwrite
#
# Clustering: generating signature file and report using k-means clustering algorithm
i.cluster group=L_2024 subgroup=res_30m \
  signaturefile=cluster_L_2024 \
  classes=10 reportfile=rep_clust_L_2024.txt --overwrite

# Classification by i.maxlik module
i.maxlik group=L_2024 subgroup=res_30m \
  signaturefile=cluster_L_2024 \
  output=L_2024_clusters reject=L_2024_cluster_reject --overwrite
#
r.colors L_2024_clusters color=haxby
r.colors shaded_relief color=grey
#
# Mapping
g.region raster=L_2024_01 -p
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast L_2024_clusters
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=L_2024_clusters title="Clusters 2024" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=Eritrea_2024 format=jpg --overwrite

# Mapping rejection probability
d.mon wx2
g.region raster=L_2024_clusters -p
r.colors L_2024_cluster_reject color=rainbow -e
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast L_2024_cluster_reject
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=L_2024_cluster_reject title="2024" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=Eritrea_2024_reject format=jpg --overwrite
#
# --------------------- MACHINE LEARNING ------------------------>
#
# Generating training pixels from an older land cover classification:
r.random input=L_2014_clusters seed=100 npoints=1000 raster=training_pixels --overwrite
#
# 1. LDA ------------------------>
# train a model using r.learn.train and training pixels
r.learn.train group=L_2024 training_map=training_pixels \
    model_name=LinearDiscriminantAnalysis n_estimators=500 save_model=lda_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2024 load_model=lda_model.gz output=lda_classification_2024 --overwrite
# check raster categories automatically applied to the classification output
r.category lda_classification_2024
#
# display
r.colors lda_classification_2024 color=byr -e
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast lda_classification_2024
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=lda_classification_2024 title="LDA 2024" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2024_LDA format=jpg --overwrite
#
# 2. GNB ------------------------>
# train a model using r.learn.train
r.learn.train group=L_2024 training_map=training_pixels \
    model_name=GaussianNB n_estimators=500 save_model=gnb_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2024 load_model=gnb_model.gz output=gnb_classification_2024 --overwrite
# check raster categories automatically applied to the classification output
r.category gnb_classification_2024
#
# display
r.colors gnb_classification_2024 color=roygbiv
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast gnb_classification_2024
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=gnb_classification_2024 title="GNB 2024" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2024_GNB format=jpg --overwrite
#
# 3. DTC ------------------------>
# train a model using r.learn.train
r.learn.train group=L_2024 training_map=training_pixels \
    model_name=DecisionTreeClassifier n_estimators=500 save_model=dtc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2024 load_model=dtc_model.gz output=dtc_classification_2024 --overwrite
# check raster categories automatically applied to the classification output
r.category dtc_classification_2024
#
# display
r.colors dtc_classification_2024 color=plasma -e
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast dtc_classification_2024
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=dtc_classification_2024 title="DTC 2024" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2024_DTC format=jpg --overwrite
#
# 4. SVM ------------------------>
# train a model using r.learn.train
r.learn.train group=L_2024 training_map=training_pixels \
    model_name=SVC n_estimators=500 save_model=svc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2024 load_model=svc_model.gz output=svc_classification_2024 --overwrite
# check raster categories automatically applied to the classification output
r.category svc_classification_2024
#
# display
r.colors svc_classification_2024 color=roygbiv -e
d.mon wx2
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast svc_classification_2024
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=svc_classification_2024 title="SVM 2024" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2024_SVM format=jpg --overwrite
