public with sharing class ViewPropertiesController {
  @AuraEnabled(cacheable=true)
  public static Project__c brokerProjectById(String projectId){
    return [Select Id, Name, Description__c, City__c,MapView__c,VideoLink__c,VirtualTour__c,Amenities__c,ProjectTag__c   from Project__c WHERE Id =: projectId limit 1];
  }

@AuraEnabled(cacheable=true)
public static List<projectDataWrapper> brokerProjects(String projectName, String projectCity, String projectCountry){
  List<projectDataWrapper> projectValues = new List<projectDataWrapper>();
  map<id,Project__c> projectmap = new map<id,Project__c>();

  if (String.isNotEmpty(projectName) && String.isNotEmpty(projectCity) && String.isNotBlank(projectCountry)) {
    projectmap = new map<id,Project__c> ([Select Id,CurrencyIsoCode,StartingPriceFrom__c, Name,CommunityNameonBrokerPortal__c,CommunityName__c, Description__c, City__c, Country__c, (SELECT Id, DocumentType__c FROM Documents__r WHERE DocumentType__c = 'Thumbnail' OR DocumentType__c = 'Project Gallery') from Project__c WHERE Name =: projectName AND City__c =: projectCity AND Country__c =: projectCountry order by StartDate__c desc,Name]);
  }else if (String.isNotEmpty(projectName) && String.isNotEmpty(projectCity)) {
    projectmap = new map<id,Project__c> ([Select Id,CurrencyIsoCode,StartingPriceFrom__c, Name,CommunityNameonBrokerPortal__c,CommunityName__c, Description__c, City__c, Country__c, (SELECT Id, DocumentType__c FROM Documents__r WHERE DocumentType__c = 'Thumbnail' OR DocumentType__c = 'Project Gallery') from Project__c WHERE Name =: projectName AND City__c =: projectCity order by StartDate__c desc,Name]);
  } else if (String.isNotEmpty(projectName) && String.isNotEmpty(projectCountry)) {
    projectmap = new map<id,Project__c> ([Select Id,CurrencyIsoCode,StartingPriceFrom__c, Name,CommunityNameonBrokerPortal__c,CommunityName__c, Description__c, City__c, Country__c, (SELECT Id, DocumentType__c FROM Documents__r WHERE DocumentType__c = 'Thumbnail' OR DocumentType__c = 'Project Gallery') from Project__c WHERE Name =: projectName AND Country__c =: projectCity order by StartDate__c desc,Name]);
  }else if (String.isNotEmpty(projectCity) && String.isNotEmpty(projectCountry)) {
    projectmap = new map<id,Project__c> ([Select Id,CurrencyIsoCode,StartingPriceFrom__c, Name,CommunityNameonBrokerPortal__c,CommunityName__c, Description__c, City__c, Country__c, (SELECT Id, DocumentType__c FROM Documents__r WHERE DocumentType__c = 'Thumbnail' OR DocumentType__c = 'Project Gallery') from Project__c WHERE Country__c =: projectCountry AND City__c =: projectCity order by StartDate__c desc,Name]);
  }else if (String.isNotEmpty(projectName)){
    projectmap = new map<id,Project__c> ([Select Id,CurrencyIsoCode,Name,StartingPriceFrom__c,CommunityNameonBrokerPortal__c,CommunityName__c, Description__c, City__c, Country__c, (SELECT Id, DocumentType__c FROM Documents__r WHERE DocumentType__c = 'Thumbnail' OR DocumentType__c = 'Project Gallery') from Project__c WHERE Name =: projectName order by StartDate__c desc,Name]);
  } else if (String.isNotEmpty(projectCity)){ 
    projectmap = new map<id,Project__c> ([Select Id,CurrencyIsoCode,Name,StartingPriceFrom__c,CommunityNameonBrokerPortal__c,CommunityName__c, Description__c, City__c, Country__c, (SELECT Id, DocumentType__c FROM Documents__r WHERE DocumentType__c = 'Thumbnail' OR DocumentType__c = 'Project Gallery') from Project__c WHERE City__c =: projectCity order by StartDate__c desc,Name]);
  } else if (String.isNotEmpty(projectCountry)){
    projectmap = new map<id,Project__c> ([Select Id,CurrencyIsoCode,Name,StartingPriceFrom__c,CommunityNameonBrokerPortal__c,CommunityName__c, Description__c, City__c, Country__c, (SELECT Id, DocumentType__c FROM Documents__r WHERE DocumentType__c = 'Thumbnail' OR DocumentType__c = 'Project Gallery') from Project__c WHERE Country__c =: projectCountry order by StartDate__c desc,Name]);
  }else {
    projectmap = new map<id,Project__c> ([Select Id,CurrencyIsoCode,Name,StartingPriceFrom__c,CommunityNameonBrokerPortal__c,CommunityName__c, Description__c, City__c, Country__c, (SELECT Id, DocumentType__c FROM Documents__r WHERE DocumentType__c = 'Thumbnail' OR DocumentType__c = 'Project Gallery') from Project__c order by StartDate__c desc,Name]);
  }

  map<Project__c,list<Unit__c>> mapOfrecords = new map<Project__c,list<Unit__c>>();

  for(Unit__c tempUnit : UnitServiceWithoutSharing.getUnitsFromProjectIds(projectmap.keySet())){
    if(!mapOfrecords.containsKey(projectmap.get(tempUnit.Project__c))){
      mapOfrecords.put(projectmap.get(tempUnit.Project__c), new list<Unit__c>());
    }
     mapOfrecords.get(projectmap.get(tempUnit.Project__c)).add(tempUnit);
    
  }

  Map<Id, String> docRelatedContentVersions = new Map<Id, String>();
  Map<String, Integer> docRelatedContentVersionsCount = new Map<String, Integer>();
  List<Id> docIdList = new List<Id>();
  for(Project__c tempProject: projectmap.values()){
    if(!tempProject.Documents__r.isEmpty()){
      for(Document__c tempDoc: tempProject.Documents__r){
        if (tempDoc.DocumentType__c == 'Thumbnail') {
          docRelatedContentVersions.put(tempDoc.Id, '');
        } else {
          docRelatedContentVersionsCount.put(tempDoc.Id, 0);
        }
        docIdList.add(tempDoc.Id);
      }
    }
  }
  for(ContentDistribution dist : [SELECT Id, RelatedRecordId, ContentDownloadUrl, DistributionPublicUrl, PdfDownloadUrl, ContentVersion.Title FROM ContentDistribution WHERE RelatedRecordId IN: docIdList] ){
    if (docRelatedContentVersions.containsKey(dist.RelatedRecordId)) {
      docRelatedContentVersions.put(dist.RelatedRecordId, dist.ContentDownloadUrl);
    } else {
      docRelatedContentVersionsCount.put(dist.RelatedRecordId, docRelatedContentVersionsCount.get(dist.RelatedRecordId) + 1);
    }
  }
  for(id key : projectmap.keySet()){
    if(!mapOfrecords.containsKey(projectmap.get(key))){
      mapOfrecords.put(projectmap.get(key),new list<Unit__c>());
    }
    if (mapOfrecords.get(projectmap.get(key)) != null) {
      String docURL = '';
      Integer docCount = 0;
      if(!projectmap.get(key).Documents__r.isEmpty()){
        for(Document__c tempDoc: projectmap.get(key).Documents__r){
          if (tempDoc.DocumentType__c == 'Thumbnail') {
            docURL = docRelatedContentVersions.get(tempDoc.Id);
          } else {
            docCount = docRelatedContentVersionsCount.get(tempDoc.Id);
          }
        }
      }
      projectValues.add(new projectDataWrapper(projectmap.get(key),mapOfrecords.get(projectmap.get(key)), docURL, docCount));
    }
  }
  
  return projectValues;
}

@AuraEnabled
public static List<String> brokerProjectGallery(String projectId){
    List<String> recordToReturn = new List<String>();
    Project__c project = [SELECT Id, Name, (SELECT Id, DocumentType__c FROM Documents__r WHERE DocumentType__c = 'Project Gallery') FROM Project__c WHERE Id =: projectId];

    List<String> docRelatedContentVersions = new List<String>();
    if(!project.Documents__r.isEmpty()){
        for(Document__c tempDoc: project.Documents__r){
            docRelatedContentVersions.add(tempDoc.Id);
        }
    }

    for(ContentDistribution dist : [SELECT Id, RelatedRecordId, ContentDownloadUrl, DistributionPublicUrl, PdfDownloadUrl, ContentVersion.Title FROM ContentDistribution WHERE RelatedRecordId IN: docRelatedContentVersions] ){
      recordToReturn.add(dist.ContentDownloadUrl);
    }
    
    return recordToReturn;
}

public class projectDataWrapper {
  @AuraEnabled
  public String projectName{ get; set;}
  @AuraEnabled
  public String projectId{ get; set;}
  @AuraEnabled
  public String projectDescription{ get; set;}
  @AuraEnabled
  public String projectCity{ get; set;}
  @AuraEnabled
  public Integer numberOfUnits{ get; set; }
  @AuraEnabled
  public Decimal minPrice{ get; set;}
  @AuraEnabled
  public String unitTypes{ get; set;}
  @AuraEnabled
  public String thumbnailURL{ get; set;}
  @AuraEnabled
  public Integer imageCount{ get; set;}
  @AuraEnabled
  public String projectCountry{ get; set;}
  @AuraEnabled
  public String currencyIsoCode{ get; set;}

   projectDataWrapper(Project__c project , list<Unit__c> units, String thumbnailURL, Integer imageCount){
    set<String> unitTypesList = new set<String>();
    String strUnitTypes;
    integer numberOfUnitsValue = 0;
    Decimal minPriceValue= 99999999;

    this.projectName = project.CommunityNameonBrokerPortal__c == false?project.Name:project.CommunityName__c;
    this.projectId = project.Id;
    this.projectDescription = project.Description__c;
    this.projectCity = project.City__c;
    this.thumbnailURL = thumbnailURL;
    this.imageCount = imageCount;
    this.projectCountry = project.Country__c;
	this.currencyIsoCode = project.CurrencyIsoCode;
    
    for (Unit__c unitObject : units) {
      if(unitObject.Status__c == Constants.UNIT_STATUS_AVAILABLE) {
        numberOfUnitsValue++;
        if(unitObject.UnitType__c != null) {
          unitTypesList.add(unitObject.UnitType__c);
        }
        /*if(unitObject.StartingPriceFrom__c!=null) {
          minPriceValue = unitObject.StartingPriceFrom__c;
        }*/
      }
    }
    //strUnitTypes = String.join( unitTypesList, ', ' ); 

    for (String unitTypeObj : unitTypesList) {
      if (strUnitTypes != null) {
        strUnitTypes = unitTypeObj + ', ' + strUnitTypes; 
      }else{
        strUnitTypes = unitTypeObj;
      }
      
    }
    if(project.StartingPriceFrom__c!=null){
      minPriceValue=project.StartingPriceFrom__c;
    }

    this.numberOfUnits = numberOfUnitsValue;
    this.minPrice = minPriceValue;
    this.unitTypes = strUnitTypes;
  }
}
}