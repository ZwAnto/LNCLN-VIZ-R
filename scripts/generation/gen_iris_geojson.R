
triMobileIris <- triMobile[, .(triMobileN = sum(jours_n), triMobileNGeo = .N), by=code_iris]

mobilierIris <- mobilier[, .(mobilierN = .N), by=.(type,lib,code_iris)]
mobilierIris <- data.table::dcast(mobilierIris,code_iris ~ type,fun.aggregate = sum,value.var = "mobilierN")

dansMaRueIris <- dansMaRue[, .(dansMaRueN = .N), by=.(type,soustype,code_iris)]
dansMaRueIrisTot <- dansMaRueIris[, .(dansMaRueN = sum(dansMaRueN,na.rm = T)), by=.(code_iris)]
dansMaRueIrisTot[, type := 'total']
dansMaRueIrisTot[, soustype := 'total']
# dansMaRueIris[grepl('rue', soustype), type := 'debordrue']
# dansMaRueIris[grepl('verre', soustype), type := 'debordverre']
dansMaRueIris[grepl('Graffitis', type), type := 'graffitis']
dansMaRueIris[grepl('abandonnés', type), type := 'abandonnes']
dansMaRueIris[grepl('Propreté', type), type := 'proprete']

dansMaRueIris <- rbind(dansMaRueIris,dansMaRueIrisTot)
dansMaRueIris <- dansMaRueIris[type %in% c('total','graffitis','abandonnes','proprete')]
dansMaRueIris <- data.table::dcast(dansMaRueIris,code_iris ~ type,fun.aggregate = sum)

trilibIris <- trilib[,.(trilibNStation = length(unique(paste0(lon,lat))), trilibNBac = .N),by=.(code_iris)]
    
iris <- merge(iris,triMobileIris)
iris <- merge(iris,mobilierIris)
iris <- merge(iris,dansMaRueIris)
iris <- merge(iris,trilibIris)

iris@data[is.na(iris@data)] <- 0

varBase <- names(iris)[!(names(iris) %in% c("code_iris","insee_com","nom_com","iris","nom_iris","typ_iris","id"))]

iris@data <- computeIndicators(iris@data)

varLoop <- names(iris)[!(names(iris) %in% c("code_iris","insee_com","nom_com","iris","nom_iris","typ_iris","id"))]
for (i in varLoop){
  
  iris@data[, c(paste0('indexArr_',i)) := as.numeric(get(i) - min(get(i), na.rm=T)), by = insee_com]
  iris@data[, c(paste0('indexArr_',i)) := get(paste0('indexArr_',i)) / max(get(paste0('indexArr_',i)), na.rm=T), by = insee_com]
  
  iris@data[is.na(get(paste0('indexArr_',i))),c(paste0('indexArr_',i)) := 0]
  
  iris@data[, c(paste0('index_',i)) := as.numeric(get(i) - min(get(i), na.rm=T))]
  iris@data[, c(paste0('index_',i)) := get(paste0('index_',i)) / max(get(paste0('index_',i)), na.rm=T)]
  
  iris@data[is.na(get(paste0('index_',i))),c(paste0('index_',i)) := 0]
  
}

iris_GEOJSON <- geojsonio::geojson_json(iris)
geojsonio::geojson_write(iris_GEOJSON, file = "json/iris.geojson")
