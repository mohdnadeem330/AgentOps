public without sharing class ECSS_CongaDocumentGenerator {
    @AuraEnabled (cacheable = true)
    public static String generateCongaComposerLink (String documentType, String recordId, String documentId)
    {
        String finalLink = '';
        String metadataName = documentType.replace(' ','_');
        //System.debug('Metadata Name : '+metadataName);
        //Get Conga Solution Record:
        List<APXTConga4__Conga_Solution__c> solutionList = [SELECT Id,APXTConga4__Button_body_field__c FROM APXTConga4__Conga_Solution__c WHERE Name=:documentType LIMIT 1];
        
        //Get Metadata Record:
        ECSS_Conga_Document_Mapping__mdt metadataRec = ECSS_Conga_Document_Mapping__mdt.getInstance(metadataName);

		System.debug('MetaData: '+metadataRec);        
        //Get the Org Domain URL:
        finalLink += URL.getOrgDomainUrl().toExternalForm();
        
        //Replace the Record Id:
        String recordIdPlaceholder = '{!'+metadataRec.Object_Name__c+ '.Id}';
        //System.debug('recordIdPlaceholder: '+recordIdPlaceholder);
        finalLink += solutionList[0].APXTConga4__Button_body_field__c.replace(recordIdPlaceholder, recordId);
        
        //Form the Query for the Record:
        String queryString = 'SELECT '+ metadataRec.Query_Fields__c + ' FROM '+ metadataRec.Object_Name__c +' WHERE Id =:recordId LIMIT 1';
        sObject FetchedRecord = Database.query(queryString);
        

        //Check if Document Record Id is Passed:
        if(documentId!=null){
            finalLink+='&AttachFile=1';
            finalLink+='&AttachmentParentID='+documentId;
        }
        //Adding the automatic generation configs
        finalLink+='&DS7=11';
        finalLink+='&defaultpdf=1';
        
        //Add Field Update:
        if(metadataRec.Fields_To_Update__c!=null){
            finalLink+= metadataRec.Fields_To_Update__c;
        }
        //System.debug('FileLink: '+finalLink);
        
        //Get the File Name:
        List<String> fetchedFields = metadataRec.File_Name__c.split('\\+');
        String fileName = '';
        for(String str: fetchedFields){
            if(str.contains('"')){
                fileName+= str.replace('"','');
            }
            else{
                fileName+=String.valueOf(fetchedRecord.get(str));
            }
        }

		finalLink += '&OFN='+fileName;
        
        //Remove extra tabs and spaces:
        finalLink = finalLink.replaceAll('[\\n\\r]', '');
        finalLink = finalLink.replaceAll('\\s+', ''); 
        system.debug('FINAL'+finalLink);
        return finalLink;
    }
    
    public static String generateCongaQueryString(String documentType,String recordId)
    {
        String finalQueryString = '';
        List<String> queryStrings = new List<String>();
        List<APXTConga4__Conga_Solution_Query__c> solutionQueries = [SELECT Id, APXTConga4__Conga_Solution__r.Name,APXTConga4__Conga_Query__r.APXTConga4__Key__c, APXTConga4__Conga_Query__r.APXTConga4__Name__c,APXTConga4__Conga_Query__r.APXTConga4__Query__c ,APXTConga4__Alias__c  FROM  APXTConga4__Conga_Solution_Query__c  WHERE APXTConga4__Conga_Solution__r.Name =:documentType];
        for(APXTConga4__Conga_Solution_Query__c congaSolQuery : solutionQueries)
        {
            String tempString = '['+congaSolQuery.APXTConga4__Alias__c +']'+congaSolQuery.APXTConga4__Conga_Query__r.APXTConga4__Key__c;
              tempString+='?pv0='+recordId;
        	queryStrings.add(tempString);
        }
        finalQueryString = String.join(queryStrings,',');
        System.debug('Final String: '+finalQueryString);
        return finalQueryString;
    }
}