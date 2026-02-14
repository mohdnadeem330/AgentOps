@RestResource (urlMapping = '/update/lead/queue')
global with sharing class UpdateLeadQueueWebService 
{
     
    @HttpPost
    global static void doPost(Lead leadRecord, String queueName, String reasonQueueChange, Boolean AutoDialerCheck)
    {   
        RestContextHandler handler = new RestContextHandler(true);
        try
        {
            Set<Id> leadTosendGenesis=new Set<Id>();
            List<Lead> toBeUpdatedLeadList 		= new List<Lead>();       
            Lead toBeUpdatedLead 				= new Lead();
           
            
            if (String.isNotBlank(queueName) && leadRecord.Id != null && String.isNotBlank(reasonQueueChange)) 
            {
                Id agentQueueId = [SELECT Id, Name 
                                   FROM Group WHERE Type = 'Queue' 
                                   AND Name = :queueName].Id;
                String leadId=leadRecord.Id;
                System.debug('*** Lead Id ***'+leadId);
                if(Constants.LEAD_AUTO_DIALER_QUEUE.equalsIgnoreCase(queueName) && AutoDialerCheck){
                     Set<String> soFieldList = Schema.getGlobalDescribe().get('Lead').getDescribe().fields.getMap().keySet();
                     List<String> strList = new List<String>();
                     strList.addAll(soFieldList);
                     String fields = string.join(strList, ',');
                     String query = 'SELECT ' + fields ;
                     query+=' FROM Lead where ID =:leadId';
                     List<Lead> newLeadList=Database.query(query);
                     Boolean autoDailerQualified= ALDAD_Validator.isAutoDialerAssigneeLead(newLeadList.get(0));
                        if(autoDailerQualified){
                            leadTosendGenesis.add(newLeadList.get(0).ID);
                            //NotUpdatedReason__c
                            toBeUpdatedLead.NotUpdatedReason__c='';
                        }else {
                            queueName=Constants.LEAD_AGENT_QUEUE;
                              agentQueueId = [SELECT Id, Name 
                                   FROM Group WHERE Type = 'Queue' 
                                   AND Name = :queueName].Id;
                            toBeUpdatedLead.NotUpdatedReason__c='Auto Dailer Validation Not Qualified';
                             
                        }
                }
                
                toBeUpdatedLead.Id 							= leadRecord.Id;
                toBeUpdatedLead.OwnerId 					= agentQueueId;
                toBeUpdatedLead.ExemptFromAssignment__c  	= false;
                toBeUpdatedLead.ReasonForQueueChange__c		= reasonQueueChange;
                toBeUpdatedLead.Status						= 'New Lead';
                
                              
                toBeUpdatedLeadList.add(toBeUpdatedLead);
                 if(!leadTosendGenesis.isEmpty() && AutoDialerCheck){
                    GenesisAutoDialerBatch genesisBatchObj=new GenesisAutoDialerBatch(leadTosendGenesis);
                    ID batchprocessid = Database.executeBatch(genesisBatchObj,1);
                    System.debug('GenesisAutoDialerBatch batchprocessid'+batchprocessid);
			    }
            }
            
            if(!toBeUpdatedLeadList.isEmpty())
            {
                update toBeUpdatedLeadList;
                handler.response.message = 'Queue Updated Successfully';
                handler.response.success = true;
                handler.response.data    = toBeUpdatedLeadList ;
                handler.finalize();
            }
            
        }
        catch (DMLException exc){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        catch(Exception ex){            
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            //handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.response.message = ex.getStackTraceString() + ex.getMessage();
            handler.finalize(ex);
        }
    }
    
    
}