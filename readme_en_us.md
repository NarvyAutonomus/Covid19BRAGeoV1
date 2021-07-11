# COVID-19 BRA WITH GEO-POINT V1

Will be used data disclosure from health departments collected from brasil.io in two ways: 
* Legacy data extraction;
* Daily Monitoring.

After will go cross with geolocalization data from IBGE (Brazilian Institute of Geography and statistics), and insert on index in elasticsearch with the purpose of be plotted in kibana dashboard.

Utilized Datasets:
* Data from health departments by brasil.io (API and Hystorical base)
* Geolocalization dataset by IBGE.

Utilized tools:
* Apache nifi
* Postgres
* Elasticsearch
* Kibana
* Docker

Outhers requirements:
* JDBC --> postgresql-42.2.11.jar nifi:/nifi/libs/
* truststore --> cacerts nifi:/nifi/libs/    | password: "senha123"

##  Environment and actions preparation in Elastic Kibana. 

1. Create schema covid, "covid_casos_full" table and a "municipios" table.

    * how will it be used for specific use will be attributed "text" however if  needs extend use, it would be advisable assign in conformity with metadata disponibilized in brasil.io

            -- SCHEMA COVID

            CREATE SCHEMA covid AUTHORIZATION postgres;


            -- covid.covid_casos_full definition

            CREATE TABLE covid.covid_casos_full (
                city text NULL,
                city_ibge_code text NULL,
                "date" text NULL,
            
            .....

            -- covid.municipios definition

            CREATE TABLE covid.municipios (
                codigo_ibge text NULL,
            
            .....


2. Prepare the environment necessary for elasticsearch and prepare some actions for data load
    1. Create the index of data mapping structure;

            PUT new_covid
            {
                "settings" : {
                    "number_of_shards" : 1
                },
                "mappings" : {
                    "properties" : {
                    ....


    2. Create the index "covid" responsible for receiving the data tranformation;

            PUT covid
            {
                "settings" : {
                    "number_of_shards" : 1
                },
                "mappings" : {
                    "properties" : {
            ....


    3. Make a reindex action fom "new_covid" to "covid";
        
            POST _reindex
            {
            "source": {
                "index": "new_covid"
            },
            "dest": {
            ......
    
    4. Create geolocalization points.

            PUT _ingest/pipeline/covid
            {
            "processors": [
                {
                "script": {
                    "source": """
                    
            ctx.location = [ Double.parseDouble(ctx.longitude) , Double.parseDouble(ctx.latitude) ]
            .....

## Load Legacy Data 

1. For data load realization we need to make responsible use of don't collect data from Api,  but use a disponibilized dataset, that way:
    1. We will do Get in https://data.brasil.io/dataset/covid19/caso_full.csv.gz;
    2. Decompression of Gzip file;
    3. Breaking in small files with maximum 15k lines;
    4. Realize insert in empty database.

        ![](images\img1.png)


2. For send to Elasticsearch it will necessary cross with geolocalization data, due to hight workload to nifi get these informations of database, we need broke in small requisitions by dates, following this flow:

    1. Using ExecuteSQLProcessor with purpose of realize a 'select distinct "date" from covid.covid_casos_full'; 

    2. Editing a SQL query with purpose of insert the date in conformity with demand and create all necessary statments;

        ![](images\img2.png) 

    3. Making a split of all statements;
    4. Execute in database with ExecuteSQL Processor, breaking in small flowfile of 1k at 5k registries;
    4. The Avro schema of return will be converted in json;
    5. A Split in unique files;
    6. Insert in elasticsearch.

#### Por fim  teremos a seguinte visão de fuxo:
![](images\img3.png) 

## Syncronization of new data 

1. Make the continued actualization flow considering the capture of consolidated data from last day. (D-1 | ${now():toNumber():minus(86400000):format('yyyy-MM-dd')}):
    1. Making GET in first page from API utilizing InvokeHTTP processor and sending your acess token in "Attributes to send" ("Authorization": "Token ${token}"), will also add a cron for start every day at 12:00; 
    2. Sending the response to "Prepare Record" process group, that's responsible for add the D-1, the "next url" of API like attribute and extract results of response  with all covid cases.
    3. After will realize a select in records using QueryRecord Processor sending  a SQL statement with "where = D-1";**
    4. Insert the new registers in database;
    5. ** During the realization of step three the original file also will be sent to another processor with purpose of extract data where is different of D-1;
    6. After, this information will be sent to the RouteOnAttribute processor, responsible for directing the next attribute url to the new InvokeHTTP if the received stream file is empty - meaning having more data to ingest considering D-1 - or exclude flowfiles with different information of D-1, ending requisitions.
    7. Case the flow continue the InvokeHTTP will direct the response to "Prepare record" continuing the flow. 

#### flow vision:
![](images\img4.png) 

2. Inserting in Elasticsearch: 

    1. Utilizing the GenerateFlowFile processor with cron at 12:20 (0 20 12 1/1 * ? *), more than sufficient for have terminate the data load flow, generating so a select considering the D-1;
    2. Will be executed a statement getting 1k at 5k registres per flowfile;
    3. Converting the Avro Schema in Json;
    4. Realize the split in unique files;
    5. Insert in Elastichsearch 

#### flow vision:
![](images\img5.png) 


## Visualization on Kibana

In maps can create a layer with base in documents and index covid, finally plot in map: 

![](images\img6.png) 

![](images\img7.png) 

![](images\img8.png) 















