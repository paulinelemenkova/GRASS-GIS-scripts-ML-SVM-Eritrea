#!/bin/sh
grass

# importing the image subset with 7 Landsat bands and display the raster map
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20180325_20200901_02_T1_SR_B1.TIF output=L_2018_01 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20180325_20200901_02_T1_SR_B2.TIF output=L_2018_02 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20180325_20200901_02_T1_SR_B3.TIF output=L_2018_03 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20180325_20200901_02_T1_SR_B4.TIF output=L_2018_04 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20180325_20200901_02_T1_SR_B5.TIF output=L_2018_05 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20180325_20200901_02_T1_SR_B6.TIF output=L_2018_06 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Eritrea/LC08_L2SP_169049_20180325_20200901_02_T1_SR_B7.TIF output=L_2018_07 extent=region resolution=region
#
g.list rast
# adding shaded relief
r.import input=/Users/polinalemenkova/grassdata/Eritrea/gebco_2023.tif output=shaded_relief extent=region --overwrite
# adding isolines
r.contour shaded_relief out=isolines step=200 --overwrite
#
g.list rast

# ---CLUSTERING AND CLASSIFICATION------------------->
# Set computational region to match the scene
g.region raster=L_2018_01 -p
# grouping data by i.group
i.group group=L_2018 subgroup=res_30m \
  input=L_2018_01,L_2018_02,L_2018_03,L_2018_04,L_2018_05,L_2018_06,L_2018_07 --overwrite
#
# Clustering: generating signature file and report using k-means clustering algorithm
i.cluster group=L_2018 subgroup=res_30m \
  signaturefile=cluster_L_2018 \
  classes=10 reportfile=rep_clust_L_2018.txt --overwrite

# Classification by i.maxlik module
i.maxlik group=L_2018 subgroup=res_30m \
  signaturefile=cluster_L_2018 \
  output=L_2018_clusters reject=L_2018_cluster_reject --overwrite
#
r.colors L_2018_clusters color=haxby
r.colors shaded_relief color=grey
#
# Mapping
g.region raster=L_2018_01 -p
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast L_2018_clusters
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=L_2018_clusters title="Clusters 2018" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=Eritrea_2018 format=jpg --overwrite

# Mapping rejection probability
d.mon wx2
g.region raster=L_2018_clusters -p
r.colors L_2018_cluster_reject color=rainbow -e
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast L_2018_cluster_reject
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=L_2018_cluster_reject title="2018" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=Eritrea_2018_reject format=jpg --overwrite

# --------------------- MACHINE LEARNING ------------------------>
#
# Generating training pixels from an older land cover classification:
r.random input=L_2014_clusters seed=100 npoints=1000 raster=training_pixels --overwrite
# Then use these training pixels to perform a classification on recent Landsat image:
#
# 1. LDA ------------------------>
# train a model using r.learn.train
r.learn.train group=L_2018 training_map=training_pixels \
    model_name=LinearDiscriminantAnalysis n_estimators=500 save_model=lda_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2018 load_model=lda_model.gz output=lda_classification_2018 --overwrite
# check raster categories automatically applied to the classification output
r.category lda_classification_2018
#
# display
r.colors lda_classification_2018 color=byr -e
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast lda_classification_2018
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=lda_classification_2018 title="LDA 2018" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2018_LDA format=jpg --overwrite
#
# 2. GNB ------------------------>
# train a model using r.learn.train
r.learn.train group=L_2018 training_map=training_pixels \
    model_name=GaussianNB n_estimators=500 save_model=gnb_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2018 load_model=gnb_model.gz output=gnb_classification_2018 --overwrite
# check raster categories automatically applied to the classification output
r.category gnb_classification_2018
#
# display
r.colors gnb_classification_2018 color=roygbiv
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast gnb_classification_2018
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=gnb_classification_2018 title="GNB 2018" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2018_GNB format=jpg --overwrite
#
# 3. DTC ------------------------>
# train a model using r.learn.train
r.learn.train group=L_2018 training_map=training_pixels \
    model_name=DecisionTreeClassifier n_estimators=500 save_model=dtc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2018 load_model=dtc_model.gz output=dtc_classification_2018 --overwrite
# check raster categories automatically applied to the classification output
r.category dtc_classification_2018
#
# display
r.colors dtc_classification_2018 color=plasma -e
d.mon wx0
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast dtc_classification_2018
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=dtc_classification_2018 title="DTC 2018" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2018_DTC format=jpg --overwrite
#
# 4. SVM ------------------------>
# train a model using r.learn.train
r.learn.train group=L_2018 training_map=training_pixels \
    model_name=SVC n_estimators=500 save_model=svc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L_2018 load_model=svc_model.gz output=svc_classification_2018 --overwrite
# check raster categories automatically applied to the classification output
r.category svc_classification_2018
#
# display
r.colors svc_classification_2018 color=roygbiv -e
d.mon wx2
d.rast shaded_relief
d.vect isolines color='100:93:134' width=0
d.rast svc_classification_2018
d.grid -g size=00:30:00 color=white width=0.1 fontsize=16 text_color=white
d.legend raster=svc_classification_2018 title="SVM 2018" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white
d.legend raster=shaded_relief title="Relief, m" title_fontsize=19 font="Helvetica" fontsize=17 bgcolor=white border_color=white -f
d.out.file output=2018_SVM format=jpg --overwrite
