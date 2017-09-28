---
layout: post
title: "Why Spark and Spark Architecture"
excerpt: "There has been a big explosion of the amount of data that is generated..."
categories: [Spark, Machine Learing]
---

#### Big Data Analytics
There has been a big explosion of the amount of data generated on a day to day basis caused by the amount of instrumentation deployed out in our world today; mobile devices, Fridges, Airplanes, ATM machines, Cookies in browsers etc. Big data analysis is the process where you take a large dataset with a goal to uncover hidden patterns, unknown corelations, market trends and other useful information. 

There are two types of Big data analytics:
- Batch Analytics
- Real-Time analytics

#### Batch Analytics

This is the process where you collect data over a period of time from instrumenation, store it and perform historical processing. It is analogous to collecting all your dirty clothes in the wash basket over a period of time and throwing it into the washing machine at one go.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-01.png)

#### Real-Time Analytics

This is the process of analyzing streams of data in real-time. One example of this is the real time analysis of credit card transactions. To catch/reduce fraud, one of the things banks do is to make sure a customers credit card transactions are all initiated from within a certian region. If it is found that the same credit card has been swipped both in California and in New York within a period of 10 minutes, then one transaction is flagged as a fradulent transaction and the customer is notified of suspicious activies in their account.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-02.png)

## Why Apache Spark Matters

Hadoop (Map Reduce) is used for Batch Processing. There is a significant time lag after the data is collected, analyized and action can be taken against the results of the analysis. Below is the typical workflow of the Map-Reduce workflow of data

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-03.png)

Spark is capable of performing batch processing against large datasets much faster than Map Reduce. Spark also has the capability of processing data in real time.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-04.png)

Spark has other advantages such as:
- Spark can be programed with mutiple launguages (R, Python, Scala, Java). Hadoop MR is mostly programed in Java. You can layer other products like Hive to give it SQL like capabilities.
- Spark can handle data input from multiple data sources eg. HDFS, Cassandra, HBASE, S3, Kafka, MongoDB, JSON, CSV, ElasticSearch, Parquet, RDMS(MYSQL, Postgress)
- Spark makes it easy to use with multiple interfaces eg Scala, Java, Python, R, SparkSQL, Spark Streaming, MLib, Graphx
- **The biggest advantage is that it is much faster than Map Reduce**


## So Spark is faster, Please remind me how Map Reduce is implemented

In order to understand why Spark is faster, you need to understand how MR works. Let's start with the typical word count Map Reduce application. Suppose you have a large sample data of 256MB of a words file and you want to run it against MR job to find out the number of times a certian word appears in the word count.

- The 256MB file will be broken down to two blocks, each block being 128MB in size and stored in HDFS data nodes. In production HDFS, you would typically have a replica set of 3 but for this example we will assume a replica of 1.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-05.png)

- Next from your client, you would write your MR job and submit it to YARN (Yet Another Resource Negotiator - part of Map Reduce 2). YARN starts a Map Resource Application Master Process container in one of the worker nodes.

- The MRApplication Master then reaches back to YARN and requests for information regarding avaialable worker nodes that have available resources and have location proximity to the 128MB.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-07.png)

- YARN schedules worker containers that will run the the word count process (MR task) and responds to the MRApplication Master container with the location of the new worker node containers. The Node Manager in each worker node manages its own process container and is responsible for restarting it if it dies, and killing it once the process is complete. It also reports back to the YARN Resource Manager on its resource usage.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-08.png)

- The MRApplication Master then starts the Map word count job in the word count container in each of the worker nodes

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-09.png)

- When the Map finished, the MRApplication master then starts the Reduce job in the word count container in each of the worker nodes. Next we will go deeper to the different phases of Map Reduce.


### ***There are three phases to a Map Reduce Job.***

#### - Mapper

- The file is read from disk in each of the word count containers into memory. There each word count container determines the number of occurences of a given word. This output is written on disk of each worker. Please note that the output has to fit in memory.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-10.png)

#### - Sort & Shuffle Phase

- All the output of the mapper phase is read from disk of each of the workers and copied on disk to a single worker for the shuffle and sort phase.
- The data is then then read from disk in the worker and put in memory for the Sort and Shuffle phase. Please note, if all the data cannot fit into the memory of the worker, the job will crush. This is a consequence of how map reduce is implemented
- The output of the shuffle phase is then written to disk as output 3

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-11.png)

#### - Reduce phase
- In the reduce phase, the results of the shuffle phase are read from disk, loaded into memory and the final results are written back to disk

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-12.png)

**Because of the number of times data has to be read and written back to disk**, Map reduce implementation is basically very slow compared to Spark RDD implementation.


## So, how is Spark implemented? Why is it faster than Map Reduce?

At its most basic level, Spark uses the RDD (Reselient Distribute Data) objects that reside in memory.  Unlike the Map Reduce implementation, a copy of the data always sits in memory rather than having to be read from disk and written to memory in various operations. **Spark is faster than Map Reduce becuase it has an *order* of magnitude lower number of disk operations.**

- RDDs are data loaded in memory. This data is Immutable. When you run a spark job(called a Transformation) against an RDD, the result is a new RDDs. This new RDD is also immutable.
- In case of a node failure, another node with access to the source data will load the data from disk and the data missing from memory is calculated using ASG. This works expecially well if the data is in HDFS where multiple nodes will have a copy of the data based on HDFS replication factor.
- All data blocks do not have to be the same size unlike Hadoop MR where all blocks are a fixed block size
- The only Disk IO required is:
	- When you are doing initial read to load the data from disk to memory
	- During the shuffling of data to different nodes
	- When there is not enough memory
	- When a node fails and data needs to be reloaded from disk.
- If you do not have enough memory, Spark uses pipelining to make use of efficient use of little memory that you have and job will not fail unlike Hadoop MR.

Spark can leverage YARN to do job scheduling similar to Hadoop Map Reduce. In fact, you can use the same Map Reduce cluster to run Spark Jobs. Once you submit your Spark jobs to YARN resource manager, it schedules the Spark Application Master Driver in a worker node. The Spark Application Master Driver then talks back to the YARN Resource Manager and requests for nodes that have locality to the data. YARN then spins up executor containers and sends that information to the Application Master Spark Driver. The Spark Driver then sends the executor jobs to run as shown below.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-13.png)

### ***There are two phases to a Spark Job.***

### Transformations

Transformations transform an existing RDD to another RDD.

- The first step is that the original data is loaded up to memory in each of the word count containers and is loaded up to memory.
- Spark **transformation** are functions that take a RDD as the input and produce one or many RDDs as the output. This RDDs reside in memory and are immutable.
- **Transformations are lazy**, i.e. are not executed immediately. When you create transformations that create RDD objects, their references to memory are created but no data is loaded or methods executed. Hadoop PIG programming also follows lazy evaluation.
-  Only after calling a Spark Action are transformations executed, this feature allows for memory not to be used up untill it is absolutely needed.
-  Also in the cause of a node failure and the loss of an RDD, the RDD would be recomputed by looking at Direct acyclic graph (DAG). More to come on DAGs

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-14.png)

**There are two kinds of transformation.**

**Narrow:**  This function operates on a single partition of a parent RDD and can be thought of as self sustained. Narrow transofrmations do not have to move data across the network
**Wide:** This function operates on data that "probably" sits in multiple partitions of the parent RDD. This transformation typically results in a shuffle where data is moved across the network and the cluster.

- In a wide transofmration, during the shuffle phase, Spark moves data between executor memory. Spark spills data to disk when there is more data shuffled onto a single executor machine than can fit in memory.

### Actions

- Actions are RDD operations that produce non-RDD values and can be thought as any RDD operation that returns a value of any type but RDD. Typically you call a action when you want a result.

**A note about DAG and Lineage**. 
- When an RDD is created, it just holds Metadata and not the results. The metadata of an RDD is composed of its transformation and its parent RDD. Using the metadata information, it is possible to recursively follow the ***lineage*** untill you get to the RDD that loads the data on disk and what transformaiton sequence led to the RDD creation. This tranformation are only executed when the results are desired during an **action**. 

 In this example reduce by Key val -> is dependant on count -> is dependant on allwords -> is dependant on words -> is dependant on "word_count.txt". In spark this is called a **Lineage** and is an example of a direct acyclic graph (DAG) which is maintained by Spark Context.

## Spark Ecosystem

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-15.png)

### *Spark Core:*

The Spark Core is just a computing engine. Its architecture is composed of a Storage System(stores the data to be processed) and Cluster Manager(Used to run Spark tasks across a cluster of machines)

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-23.png)

The foundation of Spark is composed of RDD, Transformations and Actions. The Spark Core is written in Scala which as JVMs. There are three Spark APIs. 

- **RDDs** This is the main building block of Spark. All higher level APIs decompose to RDDs. In a majority of this blog, I have used the example of using the RDD API
- *Isssues*
	- Issues with user using RDD API: is they are difficult to write, optimize to a human programer
	- Issues with user using RDD API: they cannot be optimized by Spark
	- Issues with user using RDD API: They are significatnly slow when translated from non JVM languages like Python
- **DataFrames**
	- The dataframes API provides a higher level abstraction (DSL) that allows you to use a simple query Lauguage to manipulate data. By using the Dataframs API, user queries can be optimized by Spark. The Spark User starts by writing a unresolved Query plan. This Query plan is then taken  through Spark **Catalyst** Optimizer optimization to create an RDD, Transformation code and Action. This is a similar process SQL Queries go through before they are executed by an RDMS.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-19.png)


- *Isssues*
	- Issues with user using DataFrames API: They don't give object type safety that can sometimes only show up after running long lived tasks.

- **DataSets**
	-  Datasets were introduced to allow the end user to write queries with the DSL abstraction similar to DataFrames  API  but also provides the typesafetly that is privided by RDD API.
		- Code still goes through the **Catalyst** optimizer
		- They are an extension of the **DataFrames** API
		- They are conceptually similar to RDD API (you can use types and lambdas)
		- Have introduced fast in memory encoding - Tungesten (mememory optimization). Allows to store datatypes in memory optimized format and can encode/decode on the fly as data is needed.
		- Data encoded in Tungesten reduces the amount of data sent between the nodes during shuffling phase.
		- DataSet API is even more human readable
		- Interoprates with the DataFrame API

DataSets have been in beta since Spark 1.6, in Spark 2.0 it is consisered production capabale.

### *Spark Streaming*

Spark streaming allows you to process real-time data. It splits injested data into units called DStreams which are fundametally RDDs to process real time data. It allows you to perform microbatching of real time input. It can process data from Kafka, Parquet, Hbase, Elastic Search, MySQL, Posgress, MongoDb, Flume, Akka, CSV. It can also serve as a source of input of data for the Mlib and SparkSQL

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-17.png)

### *Spark SQL*
This works on structured or semi-structured data (Json, MongoDB, Hive, Cassandra). SparkSQL works by transforming SQL calls into Transformations on RDDs. It uses a standard JDBC/ODBC SQL driver that conforms to the 2003 SQL standard.

The workflow of using SparkSQL involves, feeding it data from your datasource (Rows/Colums) This get converted into RDDs. You can then run SparkSQl jobs againt that data.

In the example I have above, I am using the RDD API that is written in Scala. Since Spark 2.0, it is now considered best practice to do all analytics in Spark SQL which sits on top of DataFrames. The reason is, SparkSQL is able to optimize the RDD Scala code to ensure that little or no shuffling happens during queries.

Also, using SparkSQL is not a lazy evaluation.

### *Spark MLlib*

In machine learning there are two kinds of algorithms.

- **Supervised Algorithms** This is where you already know some part of the output from input and using you goal is create a model to predict something new. Under supervised algorithyms, there are are main categories of algorithhms
	- *Classification*
		- Naive Bayes
		- SVM
	- *Regression*
		- Linear
		- Logistic
- **Unsupervised Algorithms** This is where you don't have any output in advance. The algorithms are left with the task of making sense of the output.
	- *Clustering*
		- K Means
	- *Dimentionality Reducation*
		- Priciple Component Analysis
		- SVD

### *GraphX*

A graph is a mathematical model used to model relationships between objects. A graph is made up of vertices and edges. Vertices are the objects and edges are the relationships between them. A directed graph is where edges have a direction to them.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-18.png)

Example of GraphX use cases are Google Maps, calculating multiple routes and showing the most optimal path, Linked in friends recommendations by looking at all your frinds and associations.


### Hadoop Ecosystem

I want to close by discussing a few things that have been layered onto MapReduce to make it much more easier to use.

#### Hive

Without Hive, Map Reduce users have to write Map Reduce Jobs using Java. This is done using three classes

- Map Java Class - Class where the Map logic is implemented
- Reduce Java Class - Class wehre the redu logic is implmented
- Main class that implementes the job Object.  - this is main function that cordinates the map calling the map and reduce methods and fields 

Hive is a SQL like interface that sits on top of Map Reduce. SQL is easier to use than Java and here are alot more developers and analysts who know SQL than Java. Here are some of the implemntation details

- Hive sits on top of HDFS and its data is stored as text and birary files partitiioned and replicated across the cluster
- Hive makes use of parallelizm of processing that you 
- Hive tanslates SQL queries into MR jobs and submits those jobs to be run in a MR cluster. The MR cluster returns the results to Hive which in turn returns the results to the end HiveQL user. You can use Hive similar to how you would use an RDMS
- Hive SQL is called HiveSQL - HiveQL is modeled after SQL but supports more built-in functions making it more like a programing lauguage that a Query lauguage. 

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-20.png)

- Hive users see's the data in HDFS in tabular format. Hive uses ***Metastore*** to bridge the translation of the data stored in files in HDFS to tabular format 
	- Metastore is a RDMS with JDBC driver. In Dev Hive comes with Derby DB, in Production you would use Posgress and MariaDB 10.
	- Metastore stores metatadata for the mapping of HDFS directories to Hive table an d holds table definaton and schema for each table

Although Hive is SQL database, it should be noted that it cannot be used like a regular RDMS for OLAP. This is because it is not ACID compliant by default and is built run high latency parallel Read Operations that operate on very large datasets. RDMS's on the other hand are ACID compliant and are built for serialised low latency RW operations that operate on small datasets.


#### Pig 

Most data that lands in big data systems is unstructured ie has an unknown schema, incomplete data nd has incosistent or records. Pig a transformation lauguage. It is a high level scripting lauguage that allows you to normalize unstructured or incomplete data and load it into HDFS. A typical worfkow would be to take raw un-normalized data, then use Pig to perform ETL (Extract, Transform and Load) and then send it into  HDFS for Hive to perform analysis on. 

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-21.png)

Please note, Pig does not create a relational databases but just creates files that reside in HDFS that have a structured or semi-structured format. Pig uses a lauguage called **PigLatin** that is a procedral, data flow lauguage that can work on multiple sources in parallel to peform ETL. Unlike HiveSQL, PigLatin code looks alot like Python, the have to explicitly describe what you want to happen to the data and Pig will figure out the most optimal way to complete your transoformation request. Unlike Hive which is used by Data Analytists, Pig is used by developers to bring all the data together in one usefull place.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-22.png)

Like Hive, Pig sits on top of Map Reduce and uses HDFS and Map Reduce
- Pig reads files from HDFS and stores intermediate records in HDFS and writes final output in HDFS
- Pig uses Map Reduce to perform ETL operations, it performs optimization of the requested ETL transformations making it very efficient. 
- Pig does not have to use Map Reduce, but can be used on to of other frameworks like Spark



















