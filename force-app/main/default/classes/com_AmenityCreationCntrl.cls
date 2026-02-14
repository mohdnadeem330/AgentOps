public class com_AmenityCreationCntrl {
    
    @AuraEnabled
    public static OperatingHours createOperatingHourForAmenity(String amenityId){
        Asset assetObj = [SELECT Id, Name FROM Asset WHERE Id = :amenityId];
        
        OperatingHours operatingHourObj = new OperatingHours();
        operatingHourObj.Name = assetObj.Name;
        operatingHourObj.TimeZone = 'Asia/Dubai';
        
        if(!Test.isRunningTest()) insert operatingHourObj;
        
        assetObj.Com_Operating_Hour_Id__c = operatingHourObj.Id;
       	update assetObj;
        
        return operatingHourObj;
    }
    
    @AuraEnabled  
    public static Map<ID, String> getFiles(String recordId){        
        List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
        List<ID> fileIDs = new List<ID>();
        for (ContentDocumentLink docLink : files) {
            fileIDs.add(docLink.ContentDocumentId);
        }
        
        List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title 
                                     FROM ContentVersion WHERE ContentDocumentId IN :fileIDs];
        Map<ID, String> mapIdTitle = new Map<ID, String>();
        for (ContentVersion docLink : docs) {
            mapIdTitle.put(docLink.ContentDocumentId, docLink.Title);
        }
        return mapIdTitle;
    } 
    
    @AuraEnabled  
    public static void deleteFiles(String sdocumentId){ 
        DELETE [SELECT Id, Title, FileType FROM ContentDocument WHERE Id = :sdocumentId];       
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getPickListValues(){
        return getPicklistValues('TimeSlot', 'DayOfWeek');
    }
    
    public static List<String> getPicklistValues(String ObjectApi_name, String Field_name){ 
        List<String> lstPickvals = new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);
        SObject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); 
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); 
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); 
        List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues(); 
        for (Schema.PicklistEntry a : pick_list_values) {
            lstPickvals.add(a.getValue());
        }
        return lstPickvals;
    }
    
    // ✅ UPDATED METHOD ONLY
    @AuraEnabled
    public static void createTimeSlots(String operatingHoursId, List<String> daysOfweekList, List<String> startTimeList, List<String> endTimeList, String assetId,  String workTypeGroupId) {
        Asset asset = [
            SELECT Id, RecordTypeName__c, Com_Maximum_members_per_Amenity__c 
            FROM Asset 
            WHERE Id = :assetId 
            LIMIT 1
        ];
        
        /*
// 1️⃣ Get ServiceResource linked to this Asset
List<ServiceResource> serviceResourceList = [
SELECT Id
FROM ServiceResource
WHERE assetId = :assetId
];
if (serviceResourceList.isEmpty()) {
throw new AuraHandledException('No Service Resource found for this Asset.');
}

// 2️⃣ Get ServiceTerritoryIds from ServiceTerritoryMember
Set<Id> territoryIds = new Set<Id>();
for (ServiceTerritoryMember serviceTerrMem : [
SELECT ServiceTerritoryId
FROM ServiceTerritoryMember
WHERE ServiceResourceId = :serviceResourceList
]) {
territoryIds.add(serviceTerrMem.ServiceTerritoryId);
}

if (territoryIds.isEmpty()) {
throw new AuraHandledException('No Service Territories found for the Service Resource.');
}

// 3️⃣ Get WorkTypeIds from ServiceTerritoryWorkType
Set<Id> workTypeIds = new Set<Id>();
for (ServiceTerritoryWorkType serviceTerrWorkType : [
SELECT WorkTypeId
FROM ServiceTerritoryWorkType
WHERE ServiceTerritoryId IN :territoryIds
]) {
workTypeIds.add(serviceTerrWorkType.WorkTypeId);
}

if (workTypeIds.isEmpty()) {
throw new AuraHandledException('No Work Types found for the Service Territories.');
}

// 4️⃣ Get WorkTypeGroupId from WorkTypeGroupMember
Id wTypeGroupId;
for (WorkTypeGroupMember workTypeGroupMember : [
SELECT WorkTypeGroupId
FROM WorkTypeGroupMember
WHERE WorkTypeId IN :workTypeIds
LIMIT 1
]) {
wTypeGroupId = workTypeGroupMember.WorkTypeGroupId;
}
*/
        //
        OperatingHours baseOH = [
            SELECT Id, Name, TimeZone
            FROM OperatingHours
            WHERE Id = :operatingHoursId
            LIMIT 1
        ];
        
        OperatingHours concurrentOH = new OperatingHours();
        concurrentOH.Name = 'Concurrent – ' + baseOH.Name ;    
        concurrentOH.TimeZone = baseOH.TimeZone; 
        asset.com_Concurrent_Operating_Hours__c  = concurrentOH.id;
        insert concurrentOH;
        update asset;
        
        Id normalOHId     = baseOH.Id;
        Id concurrentOHId = concurrentOH.Id;
        
        List<TimeSlot> normalSlots     = new List<TimeSlot>(); 
        List<TimeSlot> concurrentSlots = new List<TimeSlot>(); 
        Integer maxAppointments = asset.Com_Maximum_members_per_Amenity__c.intValue();
        
        
        for (Integer i = 0; i < daysOfweekList.size(); i++) {
            String day = daysOfweekList[i];
            
            String[] strTimeSplit = startTimeList[i].split(':');
            Time tStart = Time.newInstance(Integer.valueOf(strTimeSplit[0]),Integer.valueOf(strTimeSplit[1]), 0, 0);
            
            String[] endTimeSplit = endTimeList[i].split(':');
            Time tEnd = Time.newInstance( Integer.valueOf(endTimeSplit[0]), Integer.valueOf(endTimeSplit[1]), 0, 0);
            
            //Normal Time Slot
            TimeSlot slotObj = new TimeSlot();
            slotObj.OperatingHoursId = normalOHId;
            slotObj.Type = 'Normal';
            slotObj.DayOfWeek = day;
            slotObj.StartTime = tStart;
            slotObj.EndTime = tEnd;
            
            /*        if (wTypeGroupId != null) {
slotObj.WorkTypeGroupId = wTypeGroupId;
}*/
            normalSlots.add(slotObj);
            
            //Concurrent Time Slot
            TimeSlot concurrentSlot = new TimeSlot();
            concurrentSlot.OperatingHoursId = concurrentOHId;
            concurrentSlot.Type = 'Normal';
            concurrentSlot.MaxAppointments = maxAppointments;
            concurrentSlot.DayOfWeek = day;
            concurrentSlot.StartTime = tStart;
            concurrentSlot.EndTime   = tEnd;
            concurrentSlots.add(concurrentSlot);
        }
        
        
        insert normalSlots;
        insert concurrentSlots;
        
        asset.Com_Operating_Hour_Id__c           = normalOHId;
        asset.com_Concurrent_Operating_Hours__c  = concurrentOHId;
        update asset; 
        
        deleteLinksFromParent(assetId);
    }
    
    public static void deleteLinksFromParent(String recordId){
        List<ContentDocumentLink> linkList = [SELECT Id, LinkedEntityId, ContentDocumentId from ContentDocumentLink where LinkedEntityId =: recordId];
        
        if(!linkList.isEmpty()) delete linkList;
    }
    
    @AuraEnabled
    public static void createDocuments(String asseId, List<String> documentIdList){
        
        List<Document__c> documentList = new List<Document__c>();
        Document__c docObj;
        String amentityDocumentRT = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('Amenity_Document').getRecordTypeId();
        
        for(string documentId : documentIdList){
            docObj = new Document__c();
            docObj.RecordTypeId = amentityDocumentRT;
            docObj.ECSS_Unit__c = asseId;
            docObj.DocumentType__c = 'Others';
            docObj.Com_Amenity_Document_Id__c = documentId;
            documentList.add(docObj);
        }
        
        insert documentList;
        
        List<ContentDocumentLink> doclinkList = new List<ContentDocumentLink>();
        ContentDocumentLink docLink;
        
        for(Document__c docObj1 : documentList){
            docLink = new ContentDocumentLink();
            docLink.ContentDocumentId = docObj1.Com_Amenity_Document_Id__c;
            docLink.LinkedEntityId = docObj1.Id;
            docLink.ShareType = 'I';
            docLink.Visibility = 'InternalUsers';
            
            doclinkList.add(docLink);
        }
        
        insert doclinkList;
    }
    
    @AuraEnabled
    public static List<Product2> createPackages(String classId, List<Product2> packageList){
        system.debug('packageList'+packageList);
        Product2 packageObj;
        List<Product2> packageListToInsert = new List<Product2>();
        
        List<PricebookEntry> standardPBEList = new List<PricebookEntry>();
        List<PricebookEntry> customPBEList = new List<PricebookEntry>();
        PricebookEntry standardPbe;
        PricebookEntry customPbe;
        
        Pricebook2 standardPB = [Select Id from Pricebook2 where IsStandard = true and IsActive = true LIMIT 1];
        Pricebook2 customPB = [Select Id from Pricebook2 where Name = 'Community Price Book' and IsActive = true LIMIT 1];
        
        Product2 classObj = [Select Id, Com_Vat_Percentage__c from Product2 where Id =:classId];
        
        for(Product2 productObj : packageList){
            packageObj = new Product2();
            packageObj.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Com_Class_Package').getRecordTypeId();
            packageObj.Name = productObj.Name;
            packageObj.Com_Class__c = classId;
            packageObj.Com_Group__c = productObj.Com_Group__c;
            packageObj.Com_Commission_Type__c = productObj.Com_Commission_Type__c;
            packageObj.Com_Package_Type__c = productObj.Com_Package_Type__c;
            packageObj.Com_Total_No_of_Sessions__c = productObj.Com_Total_No_of_Sessions__c;
            packageObj.Description = productObj.Description;
            packageObj.Com_Service_Provider_Commission__c = productObj.Com_Service_Provider_Commission__c;
            packageObj.Com_Related_Party_Commission__c = productObj.Com_Related_Party_Commission__c;
            packageObj.Com_Aldar_ECSS_Commission__c = productObj.Com_Aldar_ECSS_Commission__c;
            packageObj.Com_Service_Provider_Commission_Amount__c = productObj.Com_Service_Provider_Commission_Amount__c;
            packageObj.Com_Related_Party_Commission_Amount__c = productObj.Com_Related_Party_Commission_Amount__c;
            packageObj.Com_Aldar_ECSS_Commission_Amount__c = productObj.Com_Aldar_ECSS_Commission_Amount__c;
            packageObj.Com_Fees_AED__c = productObj.Com_Fees_AED__c;
            packageObj.Com_Age_Range__c = productObj.Com_Age_Range__c;
            packageObj.Com_Maximum_No_of_Applicants__c = productObj.Com_Maximum_No_of_Applicants__c;
            packageObj.IsActive = true;
            
            packageListToInsert.add(packageObj);
            
        }
        
        if(!packageListToInsert.isEmpty()) insert packageListToInsert;
        
        for(Product2 productObj : packageListToInsert){
            standardPbe = new PricebookEntry();
            standardPbe.Product2Id = productObj.Id;
            standardPbe.Pricebook2Id = standardPB.Id;
            standardPbe.UnitPrice = productObj.Com_Fees_AED__c;
            standardPbe.IsActive = true;
            standardPbe.VAT__c = classObj.Com_Vat_Percentage__c;
            
            standardPBEList.add(standardPbe);
            
            customPbe = new PricebookEntry();
            customPbe.Product2Id = productObj.Id;
            customPbe.Pricebook2Id = customPB.Id;
            customPbe.UnitPrice = productObj.Com_Fees_AED__c;
            customPbe.IsActive = true;
            customPbe.VAT__c = classObj.Com_Vat_Percentage__c;
            customPBEList.add(customPbe);
        }
        
        if(!standardPBEList.isEmpty()) insert standardPBEList;
        if(!customPBEList.isEmpty()) insert customPBEList;
        
        return packageListToInsert;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Product2> getClassPackages(String classId){
        return [SELECT Id, Name FROM Product2 WHERE RecordType.DeveloperName = 'Com_Class_Package' AND Com_Class__c = :classId];
    }
    
    @AuraEnabled(cacheable=true)
    public static Product2 getParentClass(String packageId){
        return [SELECT Id, Com_Class__c FROM Product2 WHERE RecordType.DeveloperName = 'Com_Class_Package' AND Id = :packageId LIMIT 1];
    }
    
    @AuraEnabled
    public static void updateClassPackageOnSchedule(
        String classId,
        List<String> packgeList,
        List<String> scheduleNamesList,
        String scheduleId
    ){        
        List<String> scheduleNamesListNew = new List<String>();
        for(String str : scheduleNamesList){
            String newStr = str.trim();
            system.debug(newStr);
            scheduleNamesListNew.add(newStr);
        }
        
        List<Asset> assetListToUpdate = new List<Asset>();
        
        List<Asset> assetList = new List<Asset>([
            SELECT Id, Name, Com_Operating_Hour_Id__c, Com_Package__c, Com_Day__c,
            Time_Slot_Start_Time__c, Time_Slot_End_Time__c, Com_Time_Interval_In_Minutes__c,
            Com_Maximum_members_per_Amenity__c, Com_Class__c,
            Com_Class__r.Com_Location__City__s, Com_Class__r.Com_Location__PostalCode__s,
            Com_Class__r.Com_Location__Street__s, Com_Class__r.Com_Location__StateCode__s,
            Com_Class__r.Com_Location__CountryCode__s, Com_Class__r.Com_District__c,
            Com_Class__r.Com_Community__c, Com_Class__r.Com_Building__c,
            Com_Class__r.Com_Maximum_No_of_Applicants__c, Com_Class__r.Com_Start_Date__c,
            Com_Class__r.Com_End_Date__c
            FROM Asset
            WHERE RecordType.DeveloperName = 'Com_Class_Schedule'
            AND Com_Class__c = :classId
            AND Id = :scheduleId
        ]);
        
        if (assetList.isEmpty()) return;
        
        Map<String, Asset> assetMap = new Map<String, Asset>();
        List<OperatingHours> baseOperatingHourList = new List<OperatingHours>();
        // NEW: concurrent OH list
        List<OperatingHours> concurrentOperatingHourList = new List<OperatingHours>();
        
        Map<String, Product2> packageMap = new Map<String, Product2>();
        for (Product2 classPackage : [
            SELECT Id, Com_Maximum_No_of_Applicants__c
            FROM Product2
            WHERE RecordType.DeveloperName = 'Com_Class_Package'
            AND Id IN :packgeList
        ]) {
            packageMap.put(classPackage.Id, classPackage);
        }
        
        // Build base OH per asset (existing) – keep
        for (Asset assetObj : assetList) {
            assetMap.put(assetObj.Id, assetObj);
            
            OperatingHours oh = new OperatingHours();
            oh.Name = assetObj.Name;
            oh.TimeZone = 'Asia/Dubai';
            oh.Com_AssetId__c = assetObj.Id; // you used this to back-map after insert
            baseOperatingHourList.add(oh);
        }
        
        insert baseOperatingHourList;
        
        // Build matching concurrent OH per asset – NEW
        // We mirror names/timezone; tie back to asset via Com_AssetId__c for mapping
        for (OperatingHours baseOH : baseOperatingHourList) {
            OperatingHours conc = new OperatingHours();
            conc.Name = 'Concurrent – ' + baseOH.Name;
            conc.TimeZone = baseOH.TimeZone;
            conc.Com_AssetId__c = baseOH.Com_AssetId__c;
            concurrentOperatingHourList.add(conc);
        }
        
        insert concurrentOperatingHourList;
        
        // Map: AssetId -> {baseOHId, concOHId}
        Map<Id, Id> assetIdToBaseOH = new Map<Id, Id>();
        Map<Id, Id> assetIdToConcOH = new Map<Id, Id>();
        for (OperatingHours oh : baseOperatingHourList) {
            assetIdToBaseOH.put(oh.Com_AssetId__c, oh.Id);
        }
        for (OperatingHours oh : concurrentOperatingHourList) {
            assetIdToConcOH.put(oh.Com_AssetId__c, oh.Id);
        }
        
        // Prepare Asset updates (ONE update with both fields)
        for (OperatingHours hourObj : baseOperatingHourList) {
            Asset assetObj = assetMap.get(hourObj.Com_AssetId__c);
            
            
            Integer idx = scheduleNamesListNew.indexOf(assetObj.Name);
            
            if (idx >= 0 && idx < packgeList.size()) {
                system.debug(packgeList[idx]);
                assetObj.Com_Package__c = packgeList[idx];
            }
            
            // Copy location & schedule props
            assetObj.CountryCode      = assetObj.Com_Class__r.Com_Location__CountryCode__s;
            assetObj.Street           = assetObj.Com_Class__r.Com_Location__Street__s;
            assetObj.City             = assetObj.Com_Class__r.Com_Location__City__s;
            assetObj.PostalCode       = assetObj.Com_Class__r.Com_Location__PostalCode__s;
            assetObj.StateCode        = assetObj.Com_Class__r.Com_Location__StateCode__s;
            
            assetObj.Com_Operating_Hour_Id__c          = assetIdToBaseOH.get(assetObj.Id);
            assetObj.com_Concurrent_Operating_Hours__c = assetIdToConcOH.get(assetObj.Id);
            
            assetObj.Block_Time_Before_Minutes__c = 5;
            assetObj.Block_Time_After_Minutes__c  = 5;
            
            
            // Max applicants from package (if provided)
            Integer pkgMax = packageMap.get(assetObj.Com_Package__c).Com_Maximum_No_of_Applicants__c.intValue();
            assetObj.Com_Maximum_members_per_Amenity__c = pkgMax;
            
            assetObj.Com_No_of_Minutes_Duration__c = assetObj.Com_Time_Interval_In_Minutes__c;
            assetObj.Com_Start_DateTime__c         = assetObj.Com_Class__r.Com_Start_Date__c;
            assetObj.Com_End_Time__c               = assetObj.Com_Class__r.Com_End_Date__c;
            
            assetObj.ECSS_Zone__c  = assetObj.Com_Class__r.Com_District__c  != null ? assetObj.Com_Class__r.Com_District__c  : null;
            assetObj.Project__c    = assetObj.Com_Class__r.Com_Community__c != null ? assetObj.Com_Class__r.Com_Community__c : null;
            assetObj.Building__c   = assetObj.Com_Class__r.Com_Building__c  != null ? assetObj.Com_Class__r.Com_Building__c  : null;
            assetObj.Com_Paid_Amenity__c = 'Yes';
            assetListToUpdate.add(assetObj);
        }
        
        // Create BOTH normal & concurrent TimeSlots
        List<TimeSlot> slotList = new List<TimeSlot>();
        
        for (Asset a : assetListToUpdate) {
            if (a.Com_Day__c == null) continue;
            
            Id baseOHId = assetIdToBaseOH.get(a.Id);
            Id concOHId = assetIdToConcOH.get(a.Id);
            
            Integer maxApps = a.Com_Maximum_members_per_Amenity__c == null
                ? null
                : a.Com_Maximum_members_per_Amenity__c.intValue();
            
            for (String dayValue : a.Com_Day__c.split(';')) {
                // Normal slot (base OH)
                TimeSlot ts = new TimeSlot();
                ts.OperatingHoursId = baseOHId;
                ts.Type             = 'Normal';
                ts.DayOfWeek        = dayValue;
                ts.StartTime        = a.Time_Slot_Start_Time__c;
                ts.EndTime          = a.Time_Slot_End_Time__c;
                //  ts.WorkTypeGroupId  = assetToWorkTypeGroupIdMap.get(a.Id);
                slotList.add(ts);
                
                // Concurrent slot (concurrent OH) – with MaxAppointments
                TimeSlot cts = new TimeSlot();
                cts.OperatingHoursId = concOHId;
                cts.Type             = 'Normal';
                cts.DayOfWeek        = dayValue;
                cts.StartTime        = a.Time_Slot_Start_Time__c;
                cts.EndTime          = a.Time_Slot_End_Time__c;
                if (maxApps != null) cts.MaxAppointments = maxApps;
                slotList.add(cts);
            }
        }
        
        if (!slotList.isEmpty()) insert slotList;
        update assetListToUpdate;
        
        deleteLinksFromParent(classId);
    }
    
    
    @AuraEnabled
    public static void updateClassSchedule(String classId, List<String> scheduleNamesList, String scheduleId){
        List<Asset> assetListToUpdate = new List<Asset>();
        
        List<Asset> assetList = new List<Asset>([
            SELECT Id, Name, Com_Operating_Hour_Id__c, Com_Package__c, Com_Package__r.Com_Maximum_No_of_Applicants__c, Com_Day__c,
            Time_Slot_Start_Time__c, Time_Slot_End_Time__c, Com_Time_Interval_In_Minutes__c,
            Com_Maximum_members_per_Amenity__c, Com_Class__c,
            Com_Class__r.Com_Location__City__s, Com_Class__r.Com_Location__PostalCode__s,
            Com_Class__r.Com_Location__Street__s, Com_Class__r.Com_Location__StateCode__s,
            Com_Class__r.Com_Location__CountryCode__s, Com_Class__r.Com_District__c,
            Com_Class__r.Com_Community__c, Com_Class__r.Com_Building__c,
            Com_Class__r.Com_Maximum_No_of_Applicants__c, Com_Class__r.Com_Start_Date__c,
            Com_Class__r.Com_End_Date__c
            FROM Asset
            WHERE RecordType.DeveloperName = 'Com_Class_Schedule'
            AND Com_Class__c = :classId
            AND Id = :scheduleId
        ]);
        
        if (assetList.isEmpty()) return;
        
        Map<String, Asset> assetMap = new Map<String, Asset>();
        List<OperatingHours> baseOperatingHourList = new List<OperatingHours>();
        // NEW: concurrent OH list
        List<OperatingHours> concurrentOperatingHourList = new List<OperatingHours>();
        
        // Build base OH per asset (existing) – keep
        for (Asset assetObj : assetList) {
            assetMap.put(assetObj.Id, assetObj);
            
            OperatingHours oh = new OperatingHours();
            oh.Name = assetObj.Name;
            oh.TimeZone = 'Asia/Dubai';
            oh.Com_AssetId__c = assetObj.Id; // you used this to back-map after insert
            baseOperatingHourList.add(oh);
        }
        
        insert baseOperatingHourList;
        
        // Build matching concurrent OH per asset – NEW
        // We mirror names/timezone; tie back to asset via Com_AssetId__c for mapping
        for (OperatingHours baseOH : baseOperatingHourList) {
            OperatingHours conc = new OperatingHours();
            conc.Name = 'Concurrent – ' + baseOH.Name;
            conc.TimeZone = baseOH.TimeZone;
            conc.Com_AssetId__c = baseOH.Com_AssetId__c;
            concurrentOperatingHourList.add(conc);
        }
        
        insert concurrentOperatingHourList;
        
        // Map: AssetId -> {baseOHId, concOHId}
        Map<Id, Id> assetIdToBaseOH = new Map<Id, Id>();
        Map<Id, Id> assetIdToConcOH = new Map<Id, Id>();
        for (OperatingHours oh : baseOperatingHourList) {
            assetIdToBaseOH.put(oh.Com_AssetId__c, oh.Id);
        }
        for (OperatingHours oh : concurrentOperatingHourList) {
            assetIdToConcOH.put(oh.Com_AssetId__c, oh.Id);
        }
        
        // Prepare Asset updates (ONE update with both fields)
        for (OperatingHours hourObj : baseOperatingHourList) {
            Asset assetObj = assetMap.get(hourObj.Com_AssetId__c);
            
            // Copy location & schedule props
            assetObj.CountryCode      = assetObj.Com_Class__r.Com_Location__CountryCode__s;
            assetObj.Street           = assetObj.Com_Class__r.Com_Location__Street__s;
            assetObj.City             = assetObj.Com_Class__r.Com_Location__City__s;
            assetObj.PostalCode       = assetObj.Com_Class__r.Com_Location__PostalCode__s;
            assetObj.StateCode        = assetObj.Com_Class__r.Com_Location__StateCode__s;
            
            assetObj.Com_Operating_Hour_Id__c          = assetIdToBaseOH.get(assetObj.Id);
            assetObj.com_Concurrent_Operating_Hours__c = assetIdToConcOH.get(assetObj.Id);
            
            assetObj.Block_Time_Before_Minutes__c = 5;
            assetObj.Block_Time_After_Minutes__c  = 5;
            
            // Max applicants from package (if provided)
            Integer pkgMax = assetObj.Com_Package__r.Com_Maximum_No_of_Applicants__c.intValue();
            assetObj.Com_Maximum_members_per_Amenity__c = pkgMax;
            
            assetObj.Com_No_of_Minutes_Duration__c = assetObj.Com_Time_Interval_In_Minutes__c;
            assetObj.Com_Start_DateTime__c         = assetObj.Com_Class__r.Com_Start_Date__c;
            assetObj.Com_End_Time__c               = assetObj.Com_Class__r.Com_End_Date__c;
            
            assetObj.ECSS_Zone__c  = assetObj.Com_Class__r.Com_District__c  != null ? assetObj.Com_Class__r.Com_District__c  : '';
            assetObj.Project__c    = assetObj.Com_Class__r.Com_Community__c != null ? assetObj.Com_Class__r.Com_Community__c : '';
            assetObj.Building__c   = assetObj.Com_Class__r.Com_Building__c  != null ? assetObj.Com_Class__r.Com_Building__c  : '';
            assetObj.Com_Paid_Amenity__c = 'Yes';
            assetListToUpdate.add(assetObj);
        }
        
        // Create BOTH normal & concurrent TimeSlots
        List<TimeSlot> slotList = new List<TimeSlot>();
        
        for (Asset a : assetListToUpdate) {
            if (a.Com_Day__c == null) continue;
            
            Id baseOHId = assetIdToBaseOH.get(a.Id);
            Id concOHId = assetIdToConcOH.get(a.Id);
            
            Integer maxApps = a.Com_Maximum_members_per_Amenity__c == null
                ? null
                : a.Com_Maximum_members_per_Amenity__c.intValue();
            
            for (String dayValue : a.Com_Day__c.split(';')) {
                // Normal slot (base OH)
                TimeSlot ts = new TimeSlot();
                ts.OperatingHoursId = baseOHId;
                ts.Type             = 'Normal';
                ts.DayOfWeek        = dayValue;
                ts.StartTime        = a.Time_Slot_Start_Time__c;
                ts.EndTime          = a.Time_Slot_End_Time__c;
                //  ts.WorkTypeGroupId  = assetToWorkTypeGroupIdMap.get(a.Id);
                slotList.add(ts);
                
                // Concurrent slot (concurrent OH) – with MaxAppointments
                TimeSlot cts = new TimeSlot();
                cts.OperatingHoursId = concOHId;
                cts.Type             = 'Normal';
                cts.DayOfWeek        = dayValue;
                cts.StartTime        = a.Time_Slot_Start_Time__c;
                cts.EndTime          = a.Time_Slot_End_Time__c;
                if (maxApps != null) cts.MaxAppointments = maxApps;
                slotList.add(cts);
            }
        }
        
        if (!slotList.isEmpty()) insert slotList;
        update assetListToUpdate;
        
        deleteLinksFromParent(classId);
    }
    
    @AuraEnabled
    public static void createDocumentsForClass(String classId, List<String> documentIdList){
        
        List<Document__c> documentList = new List<Document__c>();
        Document__c docObj;
        String classDocumentRT = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('Class_Document').getRecordTypeId();
        
        for(string documentId : documentIdList){
            docObj = new Document__c();
            docObj.RecordTypeId = classDocumentRT;
            docObj.Com_Class__c = classId;
            docObj.DocumentType__c = 'Others';
            docObj.Com_Amenity_Document_Id__c = documentId;
            documentList.add(docObj);
        }
        
        insert documentList;
        
        List<ContentDocumentLink> doclinkList = new List<ContentDocumentLink>();
        ContentDocumentLink docLink;
        
        for(Document__c docObj1 : documentList){
            docLink = new ContentDocumentLink();
            docLink.ContentDocumentId = docObj1.Com_Amenity_Document_Id__c;
            docLink.LinkedEntityId = docObj1.Id;
            docLink.ShareType = 'I';
            docLink.Visibility = 'InternalUsers';
            
            doclinkList.add(docLink);
        }
        
        insert doclinkList;
    }
    
    @AuraEnabled(cacheable=true)
    public static AccountWrapper getAccountRecords(){
        Set<String> recordTypeSet = new Set<String>{'Service_Provider','Related_Party','Profit_Center'};
            List<Account> spAccountList = new List<Account>();
        List<Account> rpAccountList = new List<Account>();
        List<Account> pcAccountList = new List<Account>();
        
        for(Account accObj : [Select Id, Name, SapAccountID__c, Com_Cost_Center_SAP_Code__c, Recordtype.DeveloperName from Account where Recordtype.DeveloperName IN :recordTypeSet ORDER By Name]){
            switch on accObj.Recordtype.DeveloperName {
                when 'Service_Provider' {
                    spAccountList.add(accObj);
                }	
                when 'Related_Party' {
                    rpAccountList.add(accObj);
                }
                when 'Profit_Center' {
                    pcAccountList.add(accObj);
                }
                when else {
                }
            }
        }
        
        AccountWrapper wrapperObj = new AccountWrapper();
        wrapperObj.spAccountList = spAccountList;
        wrapperObj.rpAccountList = rpAccountList;
        wrapperObj.pcAccountList = pcAccountList;
        
        return wrapperObj;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getGroupOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Product2.Com_Group__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : ple) {
            options.add(new Map<String, String>{'label' => entry.getLabel(), 'value' => entry.getValue()});
        }
        return options;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getcommissionTypes() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Product2.Com_Commission_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : ple) {
            options.add(new Map<String, String>{'label' => entry.getLabel(), 'value' => entry.getValue()});
        }
        return options;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getpackageTypes() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Product2.Com_Package_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : ple) {
            options.add(new Map<String, String>{'label' => entry.getLabel(), 'value' => entry.getValue()});
        }
        return options;
    }
    
    @InvocableMethod(label='createParentServiceAppointments' description='Creates Class Service Appointments')
    public static void createParentServiceAppointments(List<List<ServiceAppointment>> parentAppointmentList){
        List<ServiceAppointment> appointmentList = parentAppointmentList[0];
        
        
        insert appointmentList[0];
        
        for(ServiceAppointment appointmentObj : appointmentList){
            appointmentObj.Master_Service_Appointment__c = appointmentList[0].Id;
        }
        
        appointmentList[0].Master_Service_Appointment__c = null;
        
        Database.upsert(appointmentList, true);


    }
    
    public class AccountWrapper{
        @AuraEnabled
        public List<Account> spAccountList;
        
        @AuraEnabled
        public List<Account> rpAccountList;
        
        @AuraEnabled
        public List<Account> pcAccountList;
    }
}