/***************************************************
* Date: 01 May 2024 
* Author: Smaartt 
* Description: Callout Class - Tasareeh_MepsIntegrations
***************************************************/
public class Tasareeh_MepsIntegrations implements Queueable, Database.AllowsCallouts{
    
    private String methodName;
    private String recDate;
    private Boolean runForAllObj;
    
    public Tasareeh_MepsIntegrations(String method, String dt,Boolean runForAllObj) {
        this.methodName = method;
        this.recDate = dt;
        this.runForAllObj = runForAllObj;
    }
    public Tasareeh_MepsIntegrations() {
    }
    public void execute(QueueableContext context) {
        Map<String, String> methodDataTypeMap = new Map<String, String>{
            'Parcels' => 'Parcels',
                'mapPermit' => 'Permits',
                'mapWorkflowTask' => 'WorkflowTasks',
                'mapInspections' => 'Inspections',
                'mapPermitCustomProperties' => 'PermitsCustomProperties',
                'mapFees' => 'Fees',
                'mapProfessional' => 'Professionals',
                'mapPayments' => 'Payments',   
                'mapStatusHistory' => 'StatusHistory',
                'mapWorkflowHistory' => 'WorkflowHistory',
                'mapBuildingDetails' => 'BuildingDetails',
                'mapDocument' => 'Documents',
                'mapB1Permit' => 'B1Permits'
                };
                    
                    if (methodDataTypeMap.containsKey(methodName)) {
                        String dataType = methodDataTypeMap.get(methodName);
                        String jsonBody = generateJsonBody(dataType, recDate);
                        HttpResponse response;
                        try {
                            response = TasareehIntegration_Ctrl.makeCallout('Tasareeh', jsonBody);
                            //System.debug('***RESPONSE ' + methodName + ' {' + response.getBody() + '}');
                            
                            if (response != null && response.getStatusCode() == 200) {
                                TasareehIntegration_Parser wrapper = TasareehIntegration_Parser.parse(response.getBody());
                                mapData(methodName, wrapper);
                            } else {
                                System.debug('Error: Invalid response or status code ' + (response != null ? String.valueOf(response.getStatusCode()) : 'null response'));
                                LoggerService.save(LoggerService.addApexServiceCalls('TasareehCallouts','Tasareeh_MepsIntegrations',methodName,jsonBody,(response.getBody().length() < 131072 ? response.getBody() : ''),null));
                                TasareehIntegration_Util.sendLoggerEmail();
                            }
                            String nextMethod = (runForAllObj ? getNextMethod(methodName) : '');
                            // Enqueue the next job if there is a next method and it's not the same as the current method
                            if (runForAllObj && nextMethod != null && !nextMethod.equals(methodName) /*&& !Test.isRunningTest()*/) { 
                                System.enqueueJob(new Tasareeh_MepsIntegrations(nextMethod, recDate,true));
                            }
                            if( String.isBlank(nextMethod)){
                                
                                
                                TasareehIntegration_Util.sendLoggerEmail();
                                
                               /* Date dt= Date.ValueOf(recDate);
                                date next=dt.adddays(1);
                                
                                if(next <= Date.newInstance(2025, 04, 24)){
                                    System.enqueueJob(new Tasareeh_MepsIntegrations('mapPermit', DateTime.newInstance(next.Year(),next.Month(),next.Day()).format('yyyy-MM-dd') ,false));
                                }*/
                                Database.executeBatch(new TasareehPaymentBatch('Permit_Payment__c'),100);
                                Database.executeBatch(new TasareehStatusHistoryBatch(),100);
                                
                            }
                            
                        } catch (Exception ex) {
                            //System.debug('Error during callout for method ' + methodName + ': ' + ex.getMessage());
                            LoggerService.save(LoggerService.createApexLog(ex,methodName,'Tasareeh_MepsIntegrations','Tasareeh_MepsIntegrations.execute'));
                        }
                    } else {
                        //System.debug('Error: Invalid methodName ' + methodName);
                        addLog('Tasareeh_MepsIntegrations', 'Error: Invalid methodName - ' + methodName);
                        
                    }
    }
    
    private void mapData(String methodName, TasareehIntegration_Parser wrapper) {
        switch on (methodName) {
            when 'Parcels' {
                TasareehIntegration_Ctrl.mapParcels(wrapper.Parcels);
            }
            when 'mapPermit' {
                TasareehIntegration_Ctrl.mapPermit(wrapper.Permits);
            }
            when 'mapWorkflowTask' {
                TasareehIntegration_Ctrl.mapWorkflowTask(wrapper.WorkflowTasks);
            }
            when 'mapInspections' {
                TasareehIntegration_Ctrl.mapInspections(wrapper.Inspections);
            }
            when 'mapPermitCustomProperties' {
                TasareehIntegration_Ctrl.mapPermitCustomProperties(wrapper.PermitsCustomProperties);
            }
            when 'mapFees' {
                TasareehIntegration_Ctrl.mapFees(wrapper.Fees);
            }
            when 'mapProfessional' {
                TasareehIntegration_Ctrl.mapProfessional(wrapper.Professionals);
            }
            when 'mapPayments' {
                TasareehIntegration_Ctrl.mapPayments(wrapper.Payments);
            }
            when 'mapStatusHistory' {
                TasareehIntegration_Ctrl.mapStatusHistory(wrapper.StatusHistory);
            }
            when 'mapWorkflowHistory' {
                TasareehIntegration_Ctrl.mapWorkflowHistory(wrapper.WorkflowHistory);
            }
            when 'mapBuildingDetails' {
                TasareehIntegration_Ctrl.mapBuildingDetails(wrapper.BuildingDetails);
            }
            when 'mapDocument' {
                TasareehIntegration_Ctrl.mapDocument(wrapper.Documents);
            }
            when 'mapB1Permit' {
                TasareehIntegration_Ctrl.mapB1Permit(wrapper.B1Permits);
            }
        }
    }
    
    private String generateJsonBody(String dataType, String dateValue) {
        return '{"date": "' + dateValue + '", "dataType": "' + dataType + '"}';
    }
    
    private String getNextMethod(String currentMethod) {
        Map<String, String> methodSequenceMap = new Map<String, String>{
            'Parcels' => 'mapPermit',
                'mapPermit' => 'mapWorkflowTask',
                'mapWorkflowTask' => 'mapInspections',
                'mapInspections' => 'mapPermitCustomProperties',
                'mapPermitCustomProperties' => 'mapFees',
                'mapFees' => 'mapProfessional',
                'mapProfessional' => 'mapPayments',
                'mapPayments' =>   'mapStatusHistory',
                'mapStatusHistory' => 'mapWorkflowHistory',
                'mapWorkflowHistory' => 'mapBuildingDetails',
                'mapBuildingDetails' => 'mapB1Permit'
                //'mapB1Permit' => 'mapDocument'
                };
                    
                    return methodSequenceMap.get(currentMethod);
    }
    
    public static void addLog(string processName, string message){
        Logger__c newLog = new Logger__c();
        newLog.Message__c = message;
        newLog.ExecutingProcessName__c = processName;
        newLog.ExceptionLogId__c = 'Tasareeh_MepsIntegrations-'+string.valueof(system.now());
        INSERT newLog;
    }
    
}