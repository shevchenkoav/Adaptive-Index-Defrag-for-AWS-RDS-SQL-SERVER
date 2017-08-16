# Adaptive-Index-Defrag-for-AWS-RDS-SQL-SERVER

The purpose of this procedure is to perform an intelligent defrag on one or more indexes for one or more databases. 
The 1st release (back in March 2010) was inspired by an earlier release of Michelle Ufford’s code in SQLFOOL.com site, and has since evolved to suit different and added needs. In a nutshell, this procedure automatically chooses whether to rebuild or reorganize an index according to its fragmentation level, amongst other parameters, like if page locks are allowed or the existence of LOBs. All within a specified time frame you choose, defaulting to 8 hours. The defrag priority can also be set, either on size, fragmentation level or index usage (based on range scan count), which is the default. It also handles partitioned indexes, optional statistics update (table-wide or only those related to indexes), rebuilding with the original fill factor or index padding and online operations, to name a few options. 

Fore more information regarding AdaptiveIndexDefrag please check the following blog post: https://blogs.msdn.microsoft.com/blogdoezequiel/2011/07/03/adaptive-index-defrag/

In order to work in AWS RDS SQL Server cloud offer, it was necessary to adapt AdaptiveIndexDefrag script.
Since we do not have access to MSDB or MODEL or MASTER (SQL SERVER System Databases) we adopted the database called ‘MaintenanceOS’ to install all the infrastructure needed to deploy this 
process.
