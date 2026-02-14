/*
*****************************************************************************
Apex Class Name    : DownloadDocumentsController
Created Date       : Aug 07, 2023
@description       : this Class is using in LWC downloadDocuments
@author            : Moh Sarfaraj
Modification Log:
Ver       Date              Author                               Modification
1.0    07-08-2023        Moh Sarfaraj                          Initial Version
******************************************************************************
*/
public class DownloadDocumentsController{

    /*
    ************************************************************************************
    @Method Name    : getAllActiveProjects
    @author         : Moh Sarfaraj
    @description    : It's used to get all Active Projects
    @return         : listToMapProjects List of Map
    *************************************************************************************
    */
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getAllActiveProjects(){
        List<Map<String,String>> listToMapProjects = new List<Map<String,String>>();
        for(Project__c tempProject: ProjectService.getAllActiveProjects()){
            Map<String,String> tempMap = new Map<String,String>();
            tempMap.put('label',tempProject.Name);
            tempMap.put('value',tempProject.Id);
            listToMapProjects.add(tempMap);
        }
        return listToMapProjects;
    }
    
    /*
    *************************************************************************************************
    @Method Name    : getDocumentTypes
    @author         : Moh Sarfaraj
    @description    : It's used to get all Document Types from custom label for Picklist to 
                      download type of Documents
    @return         : listToMapDocumentType List of Map
    **************************************************************************************************
    */
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getDocumentTypes(){
        List<Map<String,String>> listToMapDocumentType = new List<Map<String,String>>();
        for(String docuType : System.Label.DownloadDocumentType.split(',')){
            Map<String,String> tempMap = new Map<String,String>();
            tempMap.put('label',docuType);
            tempMap.put('value',docuType);
            listToMapDocumentType.add(tempMap);
        }
        return listToMapDocumentType;
    }
    
     /*
    ************************************************************************************
    @Method Name    : getAllDocuments
    @author         : Moh Sarfaraj
    @description    : It's used to get URL for LWC to download documents
    @param          : projectId
    @param          : documentType
    @param          : startDate
    @param          : endDate
    @return         : Wrapper objWrapper
    *************************************************************************************
    */
    @AuraEnabled
    public static DocumentWrapper getAllDocuments(String projectId, String documentType, String startDate, String endDate){
        DocumentWrapper objWrapper = new DocumentWrapper();
        try{
            if(String.isNotBlank(projectId) && String.isNotBlank(documentType) && 
               String.isNotBlank(startDate) && String.isNotBlank(endDate)){
                startDate += ' 00:00:00';
                endDate += ' 00:00:00';
                
                List<Project__c> listProject = new List<Project__c>();
                listProject = [SELECT Id,(SELECT Id FROM UnitsProject__r) FROM Project__c WHERE Id = :projectId];
                Set<Id> setUnitIds = (listProject != null && !listProject.isEmpty()) ? (new Map<Id,SObject>(listProject[0].UnitsProject__r)).keySet() : new Set<Id>{};
    
                Set<Id> setDocumentIds = new Set<Id>();
                if(setUnitIds != null && !setUnitIds.isEmpty()){
                    List<SalesOrder__c> listSalesOrders = new List<SalesOrder__c>();
                    for(SalesOrder__c objSO : [SELECT Id,(SELECT Id FROM Documents__r WHERE DocumentType__c = :documentType) 
                                       FROM SalesOrder__c WHERE Status__c NOT IN('Cancelled', 'Cancelled by User') AND 
                                       (CreatedDate >= :(DateTime.valueOf(startDate)) AND CreatedDate <= :(DateTime.valueOf(endDate))) AND
                                       Unit__c IN :setUnitIds]){
                                       
                        if(!objSO.Documents__r.isEmpty()){
                            setDocumentIds.addAll((new Map<Id,SObject>(objSO.Documents__r)).keySet());
                        }        
                    }
                }else{
                    objWrapper.success = false;
                    objWrapper.message = 'No Units Found!';
                    return objWrapper;
                }
                
                Set<Id> setCDLIds = new Set<Id>();
                if(setDocumentIds != null && !setDocumentIds.isEmpty()){
                    for(ContentDocumentLink objCDL : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :setDocumentIds]) {
                        setCDLIds.add(objCDL.ContentDocumentId);  
                    }
                }else{
                    objWrapper.success = false;
                    objWrapper.message = 'No Sales Order/ Document Records Found!';
                    return objWrapper;
                }
                
                Set<Id> setCV = new Set<Id>();
                if(setCDLIds != null && !setCDLIds.isEmpty()){
                    setCV = (new Map<Id,SObject>([SELECT Id FROM ContentVersion WHERE isLatest = true AND ContentDocumentId IN :setCDLIds])).keySet();
                }else{
                    objWrapper.success = false;
                    objWrapper.message = 'No Documents Found!';
                    return objWrapper;
                }
                
                if(setCV != null && !setCV.isEmpty()){
                    String downloadURL = System.URL.getSalesforceBaseUrl().toExternalForm();
                    downloadURL += '/sfc/servlet.shepherd/version/download/' + String.join(setCV, '/').removeEnd('/');

                    objWrapper.success = true;
                    objWrapper.message = 'Documents Successfully Downloaded!!!';
                    objWrapper.url = downloadURL;
                }else{
                    objWrapper.success = false;
                    objWrapper.message = 'No Document to download!!!';
                }
            }else{
                objWrapper.success = false;
                objWrapper.message = 'Please enter the required Inputs';
                return objWrapper;
            }
        }catch(Exception ex){
            objWrapper.success = false;
            objWrapper.message = ex.getMessage();
        }
        return objWrapper;
    }

    public class DocumentWrapper{
      @AuraEnabled  public Boolean success = false;
      @AuraEnabled  public String message;
      @AuraEnabled  public String url;
    }
}