#!/usr/bin/groovy
/**
 * This pipeline describes a multi container job, running Maven and Golang builds
 */

@Library('github.com/mugithi/jenkinsfile-pipeline@master')

def pipeline = new io.estrado.Pipeline()

podTemplate(label: 'pipeline', containers: [

  // Docker Containers that will be used, terraform - awscli - helm
  containerTemplate(name: 'kubectl', image: 'lachlanevenson/k8s-kubectl', ttyEnabled: true, command: 'cat' ),
  containerTemplate(name: 'docker', image: 'docker:1.12.6', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'terraform-aws', image: 'mugithi/terraform-awscli', ttyEnabled: true, command: 'cat' ),
  containerTemplate(name: 'helm', image: 'mugithi/helm', ttyEnabled: true, command: 'cat')],
   volumes: [hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock')]) {
   node ('pipeline') {

        def pwd = pwd()
        def chart_dir = "${pwd}/jenkins"

        //after Jenkinsfile is found in repo, perform git pull of charts
        checkout scm

        // read in required jenkins workflow config values from jenkinsfile.json
        def inputFile = readFile('jenkinsfile.json')
        def configVars = new groovy.json.JsonSlurperClassic().parseText(inputFile)
        println "pipeline configVars ==> ${configVars}"

        //set vars from jenkinsfile.json file
        def globalDNS = configVars.globals.globalDNS
        def jenkinsDNS = configVars.globals.jenkinsServer+"."+configVars.globals.globalDNS
        def appFolder = configVars.app01.appFolder

        //Tests - initialize helm
        stage ('init helm') {
          container('helm') {
            println "print helm version"
            sh "helm init"
          }
        }
        // Dry run the helm chart and make sure that the variabales are being renered
        stage ('dry run the helm chart') {
             container ('helm' ) {
                // sh "helm lint $appFolder"
                println "print helm listt"
                sh "helm list"
                println "perform dry run"
                sh "helm install $appFolder --dry-run --debug "

          }
        }

        if (env.BRANCH_NAME == 'master') {

            def appDNS = configVars.app01.name+"."+configVars.app01.globalDNS
            def awsRegion = configVars.app01.region

            stage ('create chart dns entry' ) {
              container('terraform-aws') {
                println "awscli: retrieve DNS hostid and store it in variable"
                def hostzoneid = sh(script: " aws route53 list-hosted-zones --query HostedZones[?Name==\\`$globalDNS\\`].Id --output text ", returnStdout: true).trim()
                String[] zoneidlist
                zoneidlist = hostzoneid.split('/')
                def zoneid = zoneidlist[2]
                def elbdns = sh(returnStdout: true, script: " aws route53 list-resource-record-sets --hosted-zone-id $zoneid --query ResourceRecordSets[?Name==\\`$jenkinsDNS\\`].AliasTarget[].DNSName --output text").trim()
                def elbhostid = sh(returnStdout: true, script: " aws route53 list-resource-record-sets --hosted-zone-id $zoneid --query ResourceRecordSets[?Name==\\`$jenkinsDNS\\`].AliasTarget[].HostedZoneId --output text  ").trim()

                println "terraform: perform terraform apply"
                sh( returnStdout: true, script: "terraform plan -var elb_name=$elbdns -var zone_id=$zoneid -var zone_name=$appDNS -var elb_zone_id=$elbhostid -var region=$awsRegion  --input=false")
                sh( returnStdout: true, script: "terraform apply -var zone_id=$zoneid -var zone_name=$appDNS  -var elb_zone_id=$elbhostid -var region=$awsRegion -var elb_name=$elbdns  --input=false")
                println "Navigate to this URL to access the website: https://" + appDNS
              }

            }
            stage ('install helm chart') {
                container ('helm' ) {
                    println "Starting the install of the helm chart"
                    sh "helm upgrade --install ${BRANCH_NAME} $appFolder"
                    println "Show the output of the helm install"
                }
                container('kubectl') {
                  println "print the container environment"
                  sh "kubectl describe ing"
                }
            }
        }

        if (env.BRANCH_NAME =~ "PR-*" ) {
            def branchName = env.BRANCH_NAME.toLowerCase()
            def appDNS = configVars.app01.name+"-"+branchName+"."+configVars.app01.globalDNS
            String nodotappDNS = appDNS[0..-2]
            def awsRegion = configVars.app01.region

            stage ('create chart dns entry' ) {
              container('terraform-aws') {
                //cleanup old DNS entries
                println "awscli: retrieve DNS hostid and store it in variable"
                def hostzoneid = sh(script: " aws route53 list-hosted-zones --query HostedZones[?Name==\\`$globalDNS\\`].Id --output text ", returnStdout: true).trim()
                String[] zoneidlist
                zoneidlist = hostzoneid.split('/')
                def zoneid = zoneidlist[2]
                def elbdns = sh(returnStdout: true, script: " aws route53 list-resource-record-sets --hosted-zone-id $zoneid --query ResourceRecordSets[?Name==\\`$jenkinsDNS\\`].AliasTarget[].DNSName --output text").trim()
                def elbhostid = sh(returnStdout: true, script: " aws route53 list-resource-record-sets --hosted-zone-id $zoneid --query ResourceRecordSets[?Name==\\`$jenkinsDNS\\`].AliasTarget[].HostedZoneId --output text  ").trim()

                println "terraform: perform terraform apply"
                // ENABLE DEBUG MODE "export TF_LOG=TRACE && ""
                sh( returnStdout: true, script: "terraform plan -var elb_name=$elbdns -var zone_id=$zoneid -var zone_name=$appDNS -var elb_zone_id=$elbhostid -var region=$awsRegion  --input=false")
                sh( returnStdout: true, script: "terraform apply -var zone_id=$zoneid -var zone_name=$appDNS  -var elb_zone_id=$elbhostid -var region=$awsRegion -var elb_name=$elbdns  --input=false")
                println "Navigate to this URL to access the website: https://" + appDNS
              }
            }

            stage ('install helm chart') {
              container ('helm' ) {
                // clean up all charts
                // println "Delete old PRs"
                // sh "helm delete --namespace=pull-request-$app01.name"
                println "Starting the install of the helm chart"
                sh "helm upgrade --install --set ingress.hosts=$nodotappDNS $branchName $appFolder "
                println "Show the output of the helm install"
                }
                container('kubectl') {
                  println "print the container environment"
                  sh "kubectl describe ing"
                }
            }
            stage ('clean up charts and DNS entries') {
              //Send user prompt with yes/no prompt on whether you can push site to production
              def userInput = input id: 'Promote', message: 'Are you ready to Clean up this deployment and delete DNS and Helm Files?', parameters: [choice(choices: 'Yes\nNo', description: '', name: 'answer')]
              echo ("Answer: ${userInput}")

              //If yes push to production

              if (userInput == "Yes") {
                container ('helm' ) {
                  println "Starting cleanup of the Helm Chart"
                  sh "helm delete $branchName "
                  }
                container('terraform-aws') {
                  println "awscli: retrieve DNS hostid and store it in variable"
                  def hostzoneid = sh(script: " aws route53 list-hosted-zones --query HostedZones[?Name==\\`$globalDNS\\`].Id --output text ", returnStdout: true).trim()
                  String[] zoneidlist
                  zoneidlist = hostzoneid.split('/')
                  def zoneid = zoneidlist[2]
                  def elbdns = sh(returnStdout: true, script: " aws route53 list-resource-record-sets --hosted-zone-id $zoneid --query ResourceRecordSets[?Name==\\`$jenkinsDNS\\`].AliasTarget[].DNSName --output text").trim()
                  def elbhostid = sh(returnStdout: true, script: " aws route53 list-resource-record-sets --hosted-zone-id $zoneid --query ResourceRecordSets[?Name==\\`$jenkinsDNS\\`].AliasTarget[].HostedZoneId --output text  ").trim()

                  sh( returnStdout: true, script: "terraform plan -destroy -var elb_name=$elbdns -var zone_id=$zoneid -var zone_name=$appDNS -var elb_zone_id=$elbhostid -var region=$awsRegion  --input=false")
                  sh( returnStdout: true, script: "terraform  destroy -force -var elb_name=$elbdns -var zone_id=$zoneid -var zone_name=$appDNS -var elb_zone_id=$elbhostid -var region=$awsRegion  --input=false")
                  }
              }
           }
        }
     }

}
