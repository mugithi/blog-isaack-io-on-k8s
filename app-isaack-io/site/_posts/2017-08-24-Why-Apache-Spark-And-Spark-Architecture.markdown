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

Spark uses the RDD (Reselient Distribute Data) objects that reside in memory. Unlike the Map Reduce implementation, a copy of the data always sits in memory rather than having to be read from disk and written to memory in various operations. **Spark is faster than Map Reduce becuase it has an *order* of magnitude lower number of disk operations.**

- Once the data is loaded in memory, it is immutable in memory. Output from Spark Jobs called transforms result in new RDDs being created which in turn become immutable.
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

### Transformation

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

- Actions are RDD operations that produce non-RDD values and can be thought as any RDD operation that returns a value of any type but RDD.


**A note about DAG**. In this example reduce by Key val -> is dependant on count -> is dependant on allwords -> is dependant on words -> is dependant on "word_count.txt". In spark this is called a **Lineage** and is an example of a direct acyclic graph (DAG) which is maintained by Spark Context.

## Spark Ecosystem

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-15.png)

### *Spark Core:*

This is the foundation of Spark, it is composed of RDD, Transformations and Actions. There are three Spark APIs

- **RDDs** This is the main building block of Spark. All higher level APIs decompose to RDDs. In a majority of this blog, I have used the example of using the RDD API
- *Isssues*
	- Issues with user using RDD API: is they are difficult to write, optimize to a human programer
	- Issues with user using RDD API: they cannot be optimized by Spark
	- Issues with user using RDD API: They are significatnly slow when translated from non JVM languages like Python
- **DataFrames**
	- The dataframes API provides a higher level abstraction (DSL) that allows you to use a simple query Lauguage to manipulate data. By using the Dataframs API, user queries can be optimized by Spark. The Spark User starts by writing a unresolved Query plan. This Query plan is then taken  through Spark **Catalyst** Optimizer optimization to create an RDD, Transformation code and Action. This is a similar process SQL Queries go through before they are executed by an RDMS.

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-19.png)

- Speed
	- In terms of speed, here is a graphic from DataBricks (Spark 2.0) showing a comparision between different API lauguages. Note everything is faster including faster than most native RDD Scala

![](https://raw.githubusercontent.com/mugithi/blog-isaack-io-on-k8s/master/app-isaack-io/site/img/slack-20.png)

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
