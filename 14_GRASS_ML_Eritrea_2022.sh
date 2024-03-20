#!/bin/sh

grass

# ----IMPORT AND PREPROCESSING-------------------------->
# importing the image subset with 7 Landsat bands and display the raster map
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20220304_20220314_02_T1_SR_B1.TIF output=L_2022_01 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20220304_20220314_02_T1_SR_B2.TIF output=L_2022_02 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20220304_20220314_02_T1_SR_B3.TIF output=L_2022_03 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20220304_20220314_02_T1_SR_B4.TIF output=L_2022_04 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20220304_20220314_02_T1_SR_B5.TIF output=L_2022_05 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20220304_20220314_02_T1_SR_B6.TIF output=L_2022_06 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20220304_20220314_02_T1_SR_B7.TIF output=L_2022_07 extent=region resolution=region
#
g.list rast
# shaded relief
r.import input=/Users/polinalemenkova/grassdata/Eritrea/gebco_2023.tif output=shaded_relief extent=region --overwrite
r.contour shaded_relief out=isolines step=200 --overwrite
#
g.list rast

# ---CLUSTERING AND CLASSIFICATION------------------->
# grouping data by i.group
g.region raster=L_2022_01 -p
# Set computational region to match the scene
i.group group=L_2022 subgroup=res_30m \
  input=L_2022_01,L_2022_02,L_2022_03,L_2022_04,L_2022_05,L_2022_06,L_2022_07 --overwrite
#
# Clustering: generating signature file and report using k-means clustering algorithm
i.cluster group=L_2022 subgroup=res_30m \
  signaturefile=cluster_L_2022 \
  classes=10 reportfile=rep_clust_L_2022.txt --overwrite

# Classification by i.maxlik module
i.maxlik group=L_2022 subgroup=res_30m \
  signaturefile=cluster_L_2022 \
  output=L_2022_clusters reject=L_2022_cluster_reject --overwrite
#
r.colors L_2022_clusters color=haxby
r.colors shaded_relief color=grey
#
# Mapping
g.region raster=L_2022_01 -p
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast L_2022_clusters
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=L_2022_clusters title="Clusters 2022" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=Eritrea_2022 format=jpg --overwrite

# Mapping rejection probability
d.mon wx2
g.region raster=L_2022_clusters -p
r.colors L_2022_cluster_reject color=rainbow -e
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast L_2022_cluster_reject
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=L_2022_cluster_reject title="2022" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=Eritrea_2022_reject format=jpg --overwrite
#
# --------------------- MACHINE LEARNING ------------------------>
#
# Generating training pixels from an older land cover classification:
r.random input=L_2014_clusters seed=100 npoints=1000 raster=training_pixels --overwrite
# Then use these training pixels to perform a classification on recent Landsat image:
#
# 1. LDA ------------------------>
# train a model using r.learn.train
r.learn.train group=L_2022 training_map=training_pixels \
    model_name=LinearDiscriminantAnalysis n_estimators=500 save_model=lda_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2022 load_model=lda_model.gz output=lda_classification_2022 --overwrite
# check raster categories automatically applied to the classification output
r.category lda_classification_2022
#
# display
r.colors lda_classification_2022 color=byr -e
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast lda_classification_2022
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=lda_classification_2022 title="LDA 2022" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2022_LDA format=jpg --overwrite
#
# 2. GNB ------------------------>
# train a model using r.learn.train
r.learn.train group=L_2022 training_map=training_pixels \
    model_name=GaussianNB n_estimators=500 save_model=gnb_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2022 load_model=gnb_model.gz output=gnb_classification_2022 --overwrite
# check raster categories automatically applied to the classification output
r.category gnb_classification_2022
#
# display
r.colors gnb_classification_2022 color=roygbiv
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast gnb_classification_2022
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=gnb_classification_2022 title="GNB 2022" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2022_GNB format=jpg --overwrite
#
# 3. DTC ------------------------>
# train a model using r.learn.train
r.learn.train group=L_2022 training_map=training_pixels \
    model_name=DecisionTreeClassifier n_estimators=500 save_model=dtc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2022 load_model=dtc_model.gz output=dtc_classification_2022 --overwrite
# check raster categories automatically applied to the classification output
r.category dtc_classification_2022
#
# display
r.colors dtc_classification_2022 color=plasma -e
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast dtc_classification_2022
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=dtc_classification_2022 title="DTC 2022" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2022_DTC format=jpg --overwrite
#
# 4. SVM ------------------------>
# train a model using r.learn.train
r.learn.train group=L_2022 training_map=training_pixels \
    model_name=SVC n_estimators=500 save_model=svc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2022 load_model=svc_model.gz output=svc_classification_2022 --overwrite
# check raster categories automatically applied to the classification output
r.category svc_classification_2018
#
# display
r.colors svc_classification_2022 color=roygbiv -e
d.mon wx2
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast svc_classification_2022
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=svc_classification_2022 title="SVM 2022" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2022_SVM format=jpg --overwrite
