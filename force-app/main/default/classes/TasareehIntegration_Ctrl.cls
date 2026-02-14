/***************************************************
*Date: 05 May 2024 
*Author: Smaartt
*Description: API Class to call TasreehIntegration
***************************************************/
public class TasareehIntegration_Ctrl {
    
    public static HttpResponse makeCallout(String processName,String requestBody){
        
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(processName);
        Organization org = Utilities.getOrganizationDetails();
        
        String endPointURL = mulesoftAPI.SandboxURL__c ;
        
        if(!org.IsSandbox){
            endPointURL = mulesoftAPI.ProductionURL__c ; 
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setHeader('Content-Type','application/json');
        request.setHeader('client_secret',mulesoftAPI.APIKey__c);
        request.setHeader('client_id',mulesoftAPI.APIId__c);
        request.setTimeout(120000);
        request.setEndpoint(endPointURL);
        request.setMethod(mulesoftAPI.Method__c);
        System.debug('**Request Body**'+requestBody);
        request.setBody(requestBody);

        return http.send(request);
    }
    
    // Method to map Fees
    public static void mapFees(TasareehIntegration_Parser.cls_Fees[] arrFees){
        Set<String> setIds = new Set<String>();
        try{
            for(TasareehIntegration_Parser.cls_Fees fee : arrFees){
                if(!isNull(fee.RecordId))
                    setIds.add(String.escapeSingleQuotes(fee.RecordId));
            }
            //get existing plot details from the system
            Map<String,Sobject> mapWithExtObjRecs = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c','Permit__c','RecordId__c','RecordId__c',setIds);
            
            List<Fees__c> lstFees = new List<Fees__c>();
            for(TasareehIntegration_Parser.cls_Fees fees :arrFees){
                Fees__c obj = new Fees__c();
                obj.RecordId__c = String.valueOf(fees.FeeId); 
                obj.Name = obj.RecordId__c;
                obj.Permit__c = (mapWithExtObjRecs.containsKey(fees.RecordId) && !isNull(fees.RecordId)? ((Permit__c)mapWithExtObjRecs.get(fees.RecordId)).Id : null);
                obj.FeeDescription__c = fees.FeeDescription;
                obj.Fee_Amount__c = (!isNull(fees.FeeAmount) && fees.FeeAmount > 0 ? fees.FeeAmount : obj.Fee_Amount__c);
                
                
                obj.AutoInvoiced__c = (!isNull(fees.AUTO_INVOICED) ? fees.AUTO_INVOICED : obj.AutoInvoiced__c);
                obj.Invoice_Balance_Due__c = (!isNull(fees.INVOICE_BALANCE_DUE)   ? fees.INVOICE_BALANCE_DUE : obj.Invoice_Balance_Due__c);
                obj.Invoice_Date__c = (!isNull(fees.INVOICE_DATE)   ? Datetime.valueOf(fees.INVOICE_DATE) : obj.Invoice_Date__c);
                
                obj.Invoice_Number__c = (!isNull(fees.INVOICE_AMOUNT) && fees.INVOICE_AMOUNT >= 0 ? fees.INVOICE_NUMBER : obj.Invoice_Number__c);
                obj.Invoice_Amount__c = 	(!isNull(fees.INVOICE_AMOUNT) && fees.INVOICE_AMOUNT >= 0   ? fees.INVOICE_AMOUNT : obj.Invoice_Amount__c);
                obj.Credited_Invoice_Amount__c = (!isNull(fees.INVOICE_AMOUNT) && fees.INVOICE_AMOUNT < 0 ? fees.INVOICE_AMOUNT : obj.Credited_Invoice_Amount__c);
                obj.Credited_Invoice_Number__c = (!isNull(fees.INVOICE_AMOUNT) && fees.INVOICE_AMOUNT < 0 ? fees.INVOICE_NUMBER : obj.Credited_Invoice_Number__c);
                
                
                obj.FeeApplyDate__c =   (!isNull(fees.FeeApplyDate) ? DateTime.valueOf(fees.FeeApplyDate) : null) ; 
                obj.FeeSchedule__c = fees.FeeSchedule;
                obj.Fee_Count__c = (!isNull(fees.FeeCount) ? fees.FeeCount : null);
                obj.Fee_Total__c = fees.FeeTotal;
                obj.FeeStatus__c =fees.FeeStatus;
                obj.StatusDate__c =   (!isNull(fees.StatusDate) ? DateTime.valueOf(fees.StatusDate) : null) ;
                obj.ParentId__c = fees.RecordId;
                lstFees.add(obj);
            }
            //UPSERT lstFees RecordId__c;
            
            Database.UpsertResult[] results = Database.upsert(lstFees, Fees__c.RecordId__c, false);
            List<Fees__c> lstFeesToBeUpsert = new List<Fees__c>();
            Map<String, Fees__c> mapFeesToBeUpsert = new Map<String, Fees__c>();

            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult upsertResultValue = results[i];
                for (Database.Error err : upsertResultValue.getErrors()) {
                    mapFeesToBeUpsert.put(lstFees[i].RecordId__c,lstFees[i]);
                }
            }

            if (!mapFeesToBeUpsert.values().isEmpty()) {
                UPSERT mapFeesToBeUpsert.values() RecordId__c;
            }
        }catch (DmlException ex) {
            System.debug('Error in mapFees: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapFees','TasareehIntegration_Ctrl','mapFees'));
        }
    }
    
    // Method to map building details
    public static void mapBuildingDetails(TasareehIntegration_Parser.cls_BuildingDetails[] arrBuilding){
        Set<String> setIds = new Set<String>();
        try {
            for(TasareehIntegration_Parser.cls_BuildingDetails bldg : arrBuilding){
                if(!isNull(bldg.RecordId))
                    setIds.add(String.escapeSingleQuotes(bldg.RecordId));
            }
            Map<String,Sobject> mapWithExtObjRecs = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c','Permit__c','RecordId__c','RecordId__c',setIds);
            List<Building_Details__c> lstbldg = new List<Building_Details__c>();
            for(TasareehIntegration_Parser.cls_BuildingDetails bldgs :arrBuilding){
                Building_Details__c obj = new Building_Details__c();
                obj.Building_Number__c = bldgs.BuildingNumber;
                obj.Permit__c = (mapWithExtObjRecs.containsKey(bldgs.RecordId) && !isNull(bldgs.RecordId)? ((Permit__c)mapWithExtObjRecs.get(bldgs.RecordId)).Id : null);
                obj.Number_Of_Units__c =(!isNull(bldgs.NumberOfUnits) && !checkIfAlphabetic(bldgs.NumberOfUnits) ? decimal.valueOf(bldgs.NumberOfUnits) : null); 
                obj.Number_Of_Floors__c = (!isNull(bldgs.NumberOfFloors) && !checkIfAlphabetic(bldgs.NumberOfFloors) ? decimal.valueOf(bldgs.NumberOfFloors) : null);
                obj.Number_Of_Basement_Floors__c = (!isNull(bldgs.NumberOfBasementFloors) ? bldgs.NumberOfBasementFloors : null); 
                obj.Total_Height__c = (!isNull(bldgs.TotalHeight) && !checkIfAlphabetic(bldgs.TotalHeight) ? decimal.valueOf(bldgs.TotalHeight) : null);
                obj.Building_Area__c = (!isNull(bldgs.BuildingArea) && !checkIfAlphabetic(bldgs.BuildingArea) ? decimal.valueOf(removeCommas(bldgs.BuildingArea)) : null);
                obj.Floor_Area__c = (!isNull(bldgs.FloorArea)  && !checkIfAlphabetic(bldgs.FloorArea) ? decimal.valueOf(bldgs.FloorArea) : null);
                obj.Number_Of_Entrances__c = (!isNull(bldgs.NumberOfEntrances) && !checkIfAlphabetic(bldgs.NumberOfEntrances) ? decimal.valueOf(bldgs.NumberOfEntrances) : null);
                obj.Record_Update_Date__c =   (!isNull(bldgs.RecordUpdatedDate) && !checkIfAlphabetic(bldgs.RecordUpdatedDate) ? DateTime.valueOf(bldgs.RecordUpdatedDate) : null) ; 
                obj.Record_Date__c =   (!isNull(bldgs.RecordDate) ? DateTime.valueOf(bldgs.RecordDate) : null) ; 
                obj.ParentId__c = bldgs.RecordId;
                lstbldg.add(obj);
            }
            INSERT lstbldg ;
        } catch (Exception ex) {
            System.debug('Error in mapBuildingDetails: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapBuildingDetails','TasareehIntegration_Ctrl','mapBuildingDetails'));
        }
    }

    // Method to map documents
    public static void mapDocument(TasareehIntegration_Parser.cls_Documents[] arrDocument) {
        Set<String> setIds = new Set<String>();
        Set<String> setDocIds = new Set<String>();
        Set<String> setExtDocIds = new Set<String>();
        try{
            for (TasareehIntegration_Parser.cls_Documents doc : arrDocument) {
                if (!isNull(doc.RecordId)) {
                    setIds.add(String.escapeSingleQuotes(doc.RecordId));
                    setDocIds.add(String.escapeSingleQuotes(doc.DocumentId));
                }
            }
            
            for(Tasareeh_Document__c td:[SELECT Id,Document_Id__c FROM Tasareeh_Document__c WHERE Document_Id__c=:setDocIds]){
                setExtDocIds.add(td.Document_Id__c);
            }
            setDocIds.clear();
            
            Map<String, SObject> mapWithExtObjRecs = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c', 'Permit__c', 'RecordId__c', 'RecordId__c', setIds);
            List<Tasareeh_Document__c> lstDocs = new List<Tasareeh_Document__c>();
            List<Tasareeh_Document__c> lstFinalDocs = new List<Tasareeh_Document__c>();
            Map<String, Tasareeh_Document__c> mapToUpsertDocs = new Map<String, Tasareeh_Document__c>();
            
            for (TasareehIntegration_Parser.cls_Documents docs : arrDocument) {
                if(setExtDocIds.contains(docs.DocumentId))
                    continue;
                Tasareeh_Document__c obj = new Tasareeh_Document__c();
                obj.Document_Id__c = String.valueOf(docs.DocumentId);
                obj.Record_Id__c = String.valueOf(docs.RecordId);
                obj.Name = String.valueOf(docs.DocumentId);
                obj.Doc_Name__c = docs.DocumentName;
                obj.Permit__c = mapWithExtObjRecs.containsKey(docs.RecordId) && !isNull(docs.RecordId) ? ((Permit__c) mapWithExtObjRecs.get(docs.RecordId)).Id : null;
                obj.Document_Group__c = docs.DocumentGroup;
                obj.Document_Description__c = docs.DocumentDescription;
                obj.Document_Type__c = docs.DocumentType;
                obj.Document_Category__c = docs.DocumentCategory;
                obj.File_Name__c = docs.FileName;
                obj.Upload_Date__c = !isNull(docs.UploadDate) ? Date.valueOf(docs.UploadDate) : null;
                obj.Record_Date__c = !isNull(docs.RecordDate) ? Date.valueOf(docs.RecordDate) : null;
                obj.File_Size__c = docs.FileSize;
                obj.ParentId__c = docs.RecordId;
                //lstDocs.add(obj);
                mapToUpsertDocs.put(obj.Document_Id__c, obj);
            }
            //UPSERT lstDocs Document_Id__c;
            lstFinalDocs = mapToUpsertDocs.values();
            if(lstFinalDocs.size() > 10000){
                for (Integer i = 0; i < 10000; i++) {
                    lstDocs.add(lstFinalDocs[i]);
                }
            }else{
                lstDocs = lstFinalDocs;
            }
            
            Database.UpsertResult[] results = Database.upsert(lstDocs, Tasareeh_Document__c.Document_Id__c, false);
            List<Tasareeh_Document__c> lstDocsToBeUpsert = new List<Tasareeh_Document__c>();
            Map<String, Tasareeh_Document__c> mapDocsToBeUpsert = new Map<String, Tasareeh_Document__c>();

            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult upsertResultValue = results[i];
                for (Database.Error err : upsertResultValue.getErrors()) {
                    mapDocsToBeUpsert.put(lstDocs[i].Document_Id__c,lstDocs[i]);
                }
            }

            if (!mapDocsToBeUpsert.values().isEmpty()) {
                UPSERT mapDocsToBeUpsert.values() Document_Id__c;
            }
        } catch (DmlException ex) {
            System.debug('Error in mapDocument: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapDocument','TasareehIntegration_Ctrl','mapDocument'));
        }
    }

    // Method to map permits
    public static void mapPermit(TasareehIntegration_Parser.cls_Permits[] permits) {
        List<Permit__c> lstPermits = new List<Permit__c>();
        List<Permit__c> lstParentPermits = new List<Permit__c>();
        Set<String> setPlotIds = new Set<String>();

        for (TasareehIntegration_Parser.cls_Permits permit : permits) {
            if (!isNull(permit.GisID)) {
                setPlotIds.add(String.escapeSingleQuotes(permit.GisID));
            }
        }

        Map<String, SObject> mapWithExtObjRecs = TasareehIntegration_Util.mapWithExtObjRecs('Name,GsId__c', 'Parcel__c', 'GsId__c', 'GsId__c', setPlotIds);
        Set<String> setProjServiceIds = new Set<String>();

        for (TasareehIntegration_Parser.cls_Permits permit : permits) {
            if (!isNull(permit.RecordId) && permit.RecordId.length() > 15) {
                setProjServiceIds.add(String.escapeSingleQuotes(permit.RecordId.left(15)));
            }
        }

        Map<String, SObject> mapWithProjectReg = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c', 'Permit__c', 'RecordId__c', 'RecordId__c', setProjServiceIds);

        for (TasareehIntegration_Parser.cls_Permits permit : permits) {
            Permit__c obj = new Permit__c();
            obj.Name = permit.RecordId;
            obj.RecordId__c = permit.RecordId;
            obj.Municipality__c = permit.Municipality;
            obj.ServiceName__c = permit.ServiceName;
            obj.ServiceNameArabic__c = permit.ServiceNameArabic;
            obj.Status__c = permit.CurrentRecordStatus;
            obj.ServiceCode__c = permit.ServiceCode;
            obj.KPIStatus__c = permit.CurrentKPIStatusOfRecord;
            obj.KPIAchievedInDays__c = permit.KPIAchievedInDays;
            obj.KPIStartDate__c = !isNull(permit.KPIStartDate) ? DateTime.valueOf(permit.KPIStartDate) : null;
            obj.KPIEndDate__c = !isNull(permit.KPIEndDate) ? DateTime.valueOf(permit.KPIEndDate) : null;
            obj.SubmissionDate__c = !isNull(permit.SubmissionDate) ? DateTime.valueOf(permit.SubmissionDate) : null;
            obj.Parcel_Plot__c = mapWithExtObjRecs.containsKey(permit.GisID) && !isNull(permit.GisID) ? ((Parcel__c) mapWithExtObjRecs.get(permit.GisID)).Id : null;
            obj.KPIEndStatusType__c = !isNull(permit.KPIEndStatusType) ? permit.KPIEndStatusType : '';
            obj.KPIStartStatus__c = permit.KPIStartStatus;
            obj.KPIEndStatus__c = permit.KPIEndStatus;
            obj.Channel__c = permit.channel;
            obj.Happiness_Feedback__c = permit.HappinessFeedback;
            obj.Happiness_Comment__c = permit.HappinessComment;
            obj.CreatedBy__c = permit.CreatedBy;
            obj.LastStatusDate__c = !isNull(permit.LastStatusDate) ? DateTime.valueOf(permit.LastStatusDate) : null;
            obj.Rec_Date__c = !isNull(permit.LastStatusDate) ? DateTime.valueOf(permit.LastStatusDate) : null;
            obj.ParentId__c = permit.GisID;
            obj.Sub_Service_Value1__c = permit.SubServiceValue;
            obj.Sub_Service_Value_Arabic__c = permit.SubServiceValueArabic;
            obj.Transaction_Code__c = permit.TransactionCode;
            obj.Payment_Status__c = permit.PaymentStatus;
            obj.Payment_Amount__c = !isNull(permit.PaymentAmount) ? Decimal.valueOf(permit.PaymentAmount) : 0.0;
            obj.Payment_Date__c = !isNull(permit.PaymentDate) ? DateTime.valueOf(permit.PaymentDate) : null;

            List<String> recIdList = permit.RecordId.split('-');
            if (permit.RecordId.length() > 15 && (recIdList[2].length() == 5 || recIdList[2].length() == 6)) {
                obj.Project_Registration__r = new Permit__c(RecordId__c = permit.RecordId.left(15));
                lstPermits.add(obj);
            } else {
                lstParentPermits.add(obj);
            }
        }

        try {
            UPSERT lstParentPermits RecordId__c;
            Database.UpsertResult[] results = Database.upsert(lstPermits, Permit__c.RecordId__c, false);
            List<Permit__c> lstPermitsToBeUpsert = new List<Permit__c>();
            Map<String, Permit__c> mapPermitsToBeUpsert = new Map<String, Permit__c>();
            
            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult upsertResultValue = results[i];
                for (Database.Error err : upsertResultValue.getErrors()) {
                    lstPermits[i].Project_Registration__r = null;
                    lstPermitsToBeUpsert.add(lstPermits[i]);
                    mapPermitsToBeUpsert.put(lstPermits[i].RecordId__c, lstPermits[i]);
                }
            }

            if (!mapPermitsToBeUpsert.values().isEmpty()) { //if (!lstPermitsToBeUpsert.isEmpty()) {
                UPSERT mapPermitsToBeUpsert.values() RecordId__c;
            }
        } catch (DmlException ex) {
            System.debug('Error in mapPermit: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapPermit','TasareehIntegration_Ctrl','mapPermit'));
        }
    }

    // Method to map B1 Permits
    public static void mapB1Permit(TasareehIntegration_Parser.cls_B1Permits[] b1Permits) {
        List<Permit__c> lstPermits = new List<Permit__c>();
        List<Permit__c> lstParentPermits = new List<Permit__c>();
        Set<String> setPlotIds = new Set<String>();

        Set<String> setProjIds = new Set<String>();
        for (TasareehIntegration_Parser.cls_B1Permits b1PermitRec : b1Permits) {
            if (!isNull(b1PermitRec.RecordId)) {
                setProjIds.add(String.escapeSingleQuotes(b1PermitRec.RecordId));
            }
        }

        Map<String, SObject> mapWithPermit = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c', 'Permit__c', 'RecordId__c', 'RecordId__c', setProjIds);

        for (TasareehIntegration_Parser.cls_B1Permits b1PermitRec : b1Permits) {
            Permit__c objPermit = new Permit__c();
            objPermit.Name = b1PermitRec.RecordId;
            objPermit.RecordId__c = b1PermitRec.RecordId;
            objPermit.Category__c = b1PermitRec.ServiceCode;
            objPermit.B1_Permit_Status__c = b1PermitRec.RecordStatus;
            objPermit.Record_Status_Arabic__c = b1PermitRec.RecordStatusArabic;
            objPermit.Record_Class__c = b1PermitRec.RecordClass;
            objPermit.Balance__c = b1PermitRec.Balance;
            objPermit.Project_Description__c = b1PermitRec.ProjectDescription;
            objPermit.Last_Status_Date_B1Permit__c = (!isNull(b1PermitRec.LastStatusDate) ?  DateTime.valueOf(b1PermitRec.LastStatusDate) : null);
            objPermit.Submission_Date_B1_Permit__c = (!isNull(b1PermitRec.SubmissionDate) ?  DateTime.valueOf(b1PermitRec.SubmissionDate) : null);
            objPermit.Sector__c = b1PermitRec.Sector;
            objPermit.Plot_Number__c = b1PermitRec.PlotNumber;
            objPermit.Zone__c = b1PermitRec.Zone;
            objPermit.Sector_Arabic__c = b1PermitRec.SectorArabic;
            objPermit.Zone_Arabic__c = b1PermitRec.ZoneArabic;
            objPermit.Sub_Service_Name__c = b1PermitRec.SubServiceName;
            objPermit.Sub_Service_Value1__c = b1PermitRec.SubServiceValue;
            objPermit.User_Id__c = b1PermitRec.UserId;
            objPermit.Sub_Service_Value_Arabic__c = b1PermitRec.SubServiceValueArabic;
            objPermit.Application_Sub_Type__c = b1PermitRec.ApplicationSubType;
            objPermit.Application_SubType_Arabic__c = b1PermitRec.ApplicationSubTypeAr;
            List<String> recIdList = b1PermitRec.RecordId.split('-');
            
            if(b1PermitRec.RecordId.length() > 15 && (recIdList[2].length() == 5 || recIdList[2].length() == 6)){
                objPermit.Project_Registration__r = new Permit__c (RecordId__c = b1PermitRec.RecordId.left(15));
                lstPermits.add(objPermit);
            }else{
                lstParentPermits.add(objPermit);
            }
        }
        
        try {
            Database.UpsertResult[] results = Database.upsert(lstPermits, Permit__c.RecordId__c, false);
            List<Permit__c> lstPermitsToBeUpsert = new List<Permit__c>();
            Map<String, Permit__c> mapB1PermitsToBeUpsert = new Map<String, Permit__c>();
            
            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult upsertResultValue = results[i];
                for (Database.Error err : upsertResultValue.getErrors()) {
                    lstPermits[i].Project_Registration__r = null;
                    lstPermitsToBeUpsert.add(lstPermits[i]);
                    mapB1PermitsToBeUpsert.put(lstPermits[i].RecordId__c, lstPermits[i]);
                }
            }

            if (!mapB1PermitsToBeUpsert.values().isEmpty()) {
                UPSERT mapB1PermitsToBeUpsert.values() RecordId__c;
            }
        } catch (DmlException ex) {
            System.debug('Error in mapB1Permit: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapB1Permit','TasareehIntegration_Ctrl','mapB1Permit'));
        }
    }
    
    
    // Method to map parcels with error handling
    public static void mapParcels(TasareehIntegration_Parser.cls_Parcels[] parcels) {
        List<Parcel__c> lstUnits = new List<Parcel__c>();
        Set<String> setds = new Set<String>();
        Map<String,String> mapGisWthPlotSector = new Map<String,String>();
        try {
            for (TasareehIntegration_Parser.cls_Parcels parcel : parcels) {
                String parcelExtId = parcel.GisID + '-' + parcel.Sector + '-' + parcel.LandUse + '-' + parcel.Municipality + '-' + parcel.PlotNumber;
                if (setds.contains(parcelExtId)) continue;
                
                Parcel__c obj = new Parcel__c();
                obj.Name = parcel.GisID;
                obj.GsId__c = parcel.GisID;
                obj.Zone__c = parcel.Zone;
                obj.plotArea__c = !isNull(parcel.PlotArea) ? Decimal.valueOf(parcel.PlotArea) : null;
                obj.Sector__c = parcel.Sector;
                obj.Street__c = parcel.street;
                obj.LandUse__c = parcel.LandUse;
                obj.LandUseArabic__c = parcel.LandUseArabic;
                obj.LandUseIdentifier__c = parcel.LandUseIdentifier;
                obj.Municipality__c = parcel.Municipality;
                obj.PlotNumber__c = !isNull(parcel.PlotNumber) ? parcel.PlotNumber : null;
                obj.Municipality_Owner__c = !isNull(parcel.PlotWidth) ? parcel.PlotWidth : null;
                obj.SecondaryLandUse__c = parcel.SecondaryLandUse;
                obj.SecondaryLandUseArabic__c = parcel.SecondaryLandUseArabic;
                obj.SitePlanNumber__c = parcel.SitePlanNumber;
                obj.StatusDate__c = !isNull(parcel.statusDate) ? DateTime.valueOf(parcel.statusDate) : null;
                obj.Parcel_Id__c = obj.GsId__c + '-' + obj.Sector__c + '-' + obj.LandUse__c + '-' + obj.Municipality__c + '-' + obj.PlotNumber__c;

                lstUnits.add(obj);
                setds.add(obj.Parcel_Id__c);
                if(obj.Sector__c != null && obj.PlotNumber__c != null){
                    mapGisWthPlotSector.put(obj.GsId__c,obj.PlotNumber__c+'__'+obj.Sector__c);
                }
            }
            Database.UpsertResult[] results = Database.upsert(lstUnits, Parcel__c.GsId__c, false);
            Map<String, Parcel__c> mapParcelsToBeUpsert = new Map<String, Parcel__c>();

            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult upsertResultValue = results[i];
                for (Database.Error err : upsertResultValue.getErrors()) {
                    mapParcelsToBeUpsert.put(lstUnits[i].GsId__c,lstUnits[i]);
                }
            }

            if (!mapParcelsToBeUpsert.values().isEmpty()) {
                UPSERT mapParcelsToBeUpsert.values() GsId__c;
            }
            if(!mapGisWthPlotSector.isEmpty()) 
                linkUnitWithPlot(mapGisWthPlotSector);//call future method to link
                  
        } catch (Exception ex) {
            System.debug('Error in mapParcels: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapParcels','TasareehIntegration_Ctrl','mapParcels'));
        }
    }
    
    @future
    public static void linkUnitWithPlot(Map<String,String> mapGisWthPlotSect){
        try{
            Map<String,Set<String>> mapSetPlot = new Map<String,Set<String>>();
            List<Unit__c> lstUnitsToUpdate = new List<Unit__c>();
            
            Map<String,String> mapParcelIdWithPlotSect = new  Map<String,String>();
            for(Parcel__c p :[SELECT Id,PlotNumber__c,Sector__c FROM Parcel__c WHERE GsId__c=: mapGisWthPlotSect.keySet()]){
                mapParcelIdWithPlotSect.put(p.PlotNumber__c+'__'+p.Sector__c, p.Id);
            }
            
            for(String gis:mapGisWthPlotSect.keySet()){
                String plotSect = mapGisWthPlotSect.get(gis);
                List<string> lstSplt = plotSect.split('__');
                if(!mapSetPlot.containsKey(lstSplt[0]))
                    mapSetPlot.put(lstSplt[0],new Set<string>());
                mapSetPlot.get(lstSplt[0]).add(lstSplt[1]);
            }
            for(Unit__c u:[SELECT Id,ADMSectorName__c,TasareehPlot__c,ADMUnitNumber__c FROM Unit__c WHERE ADMUnitNumber__c =:mapSetPlot.keySet() AND TasareehPlot__c=NULL]){
                Set<String> setSectors = mapSetPlot.get(u.ADMUnitNumber__c);
                if(setSectors.contains(u.ADMSectorName__c)){
                    if(mapParcelIdWithPlotSect.containsKey(u.ADMUnitNumber__c+'__'+u.ADMSectorName__c))
                        u.TasareehPlot__c = mapParcelIdWithPlotSect.get(u.ADMUnitNumber__c+'__'+u.ADMSectorName__c);
                    lstUnitsToUpdate.add(u);
                }
            }
            UPDATE lstUnitsToUpdate;
        }catch (DmlException ex) {
            System.debug('Error in linkUnitWithPlot: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'linkUnitWithPlot','TasareehIntegration_Ctrl','linkUnitWithPlot'));
        }
        
    }

    // Method to map inspections with error handling
    public static void mapInspections(TasareehIntegration_Parser.cls_Inspections[] inspections) {
        List<Inspections__c> lstInsp = new List<Inspections__c>();
        Set<String> setUnqueIds = new Set<String>();
        
        try {
            for (TasareehIntegration_Parser.cls_Inspections insp : inspections) {
                if (!isNull(insp.RecordId)) setUnqueIds.add(String.escapeSingleQuotes(insp.RecordId));
            }

            Map<String, Sobject> mapWithExtObjRecs = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c', 'Permit__c', 'RecordId__c', 'RecordId__c', setUnqueIds);
            if(!setUnqueIds.isEmpty()) setUnqueIds.clear();

            for (TasareehIntegration_Parser.cls_Inspections insp : inspections) {
                if (setUnqueIds.contains(String.valueOf(insp.InspectionNumber))) continue;

                Inspections__c obj = new Inspections__c();
                obj.InspectionNumber__c = Integer.valueOf(insp.InspectionNumber);
                obj.Name = String.valueOf(obj.InspectionNumber__c);
                obj.Permit__c = mapWithExtObjRecs.containsKey(insp.RecordId) && !isNull(insp.RecordId) ? ((Permit__c) mapWithExtObjRecs.get(insp.RecordId)).Id : null;
                obj.InspectionType__c = insp.InspectionType;
                obj.Inspector__c = insp.Inspector;
                obj.ScheduleDate__c = !isNull(insp.ScheduleDate) ? DateTime.valueOf(insp.ScheduleDate) : null;
                obj.InspectionDate__c = !isNull(insp.InspectionDate) ? DateTime.valueOf(insp.InspectionDate) : null;
                obj.InspectionStatus__c = insp.InspectionStatus;
                obj.InspectorComments__c = insp.InspectorComments;
                obj.RecordDate__c = !isNull(insp.RecordDate) ? DateTime.valueOf(insp.RecordDate) : null;
                obj.ParentId__c = insp.RecordId;
                obj.Department__c = insp.Department;
                obj.InspectorId__c = insp.UserId;
                lstInsp.add(obj);
                setUnqueIds.add(obj.Name);
            }
            UPSERT lstInsp InspectionNumber__c;
        } catch (Exception ex) {
            System.debug('Error in mapInspections: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapInspections','TasareehIntegration_Ctrl','mapInspections'));
        }
    }

    // Method to map permit custom properties with error handling
    public static void mapPermitCustomProperties(TasareehIntegration_Parser.cls_PermitsCustomProperties[] customProps) {
        List<Permit_Custom_Property__c> lst = new List<Permit_Custom_Property__c>();
        Set<String> setUnqueIds = new Set<String>();

        try {
            for (TasareehIntegration_Parser.cls_PermitsCustomProperties prop : customProps) {
                if (!isNull(prop.RecordId)) setUnqueIds.add(String.escapeSingleQuotes(prop.RecordId));
            }

            Map<String, Sobject> mapWithExtObjRecs = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c', 'Permit__c', 'RecordId__c', 'RecordId__c', setUnqueIds);

            for (TasareehIntegration_Parser.cls_PermitsCustomProperties prop : customProps) {
                if (!mapWithExtObjRecs.containsKey(prop.RecordId)) continue;

                Permit_Custom_Property__c obj = new Permit_Custom_Property__c();
                obj.Permit__c = mapWithExtObjRecs.containsKey(prop.RecordId) && !isNull(prop.RecordId) ? ((Permit__c) mapWithExtObjRecs.get(prop.RecordId)).Id : null;
                obj.ASIFieldName__c = prop.ASIFieldName;
                obj.ASIFieldValue__c = prop.ASIFieldValue;
                obj.ASIFieldGroup__c = prop.ASIFieldGroup;
                obj.RecordDate__c = DateTime.valueOf(prop.RecordDate);
                obj.ParentId__c = prop.RecordId;
                lst.add(obj);
            }
            insert lst;
        } catch (Exception ex) {
            System.debug('Error in mapPermitCustomProperties: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapPermitCustomProperties','TasareehIntegration_Ctrl','mapPermitCustomProperties'));
        }
    }

    // Method to map professionals with error handling
    public static void mapProfessional(TasareehIntegration_Parser.cls_Professionals[] professionals) {
        List<Professional__c> lst = new List<Professional__c>();
        Set<String> setUnqueIds = new Set<String>();

        try {
            for (TasareehIntegration_Parser.cls_Professionals prof : professionals) {
                if (!isNull(prof.RecordId)) setUnqueIds.add(String.escapeSingleQuotes(prof.RecordId));
            }

            Map<String, Sobject> mapWithExtObjRecs = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c', 'Permit__c', 'RecordId__c', 'RecordId__c', setUnqueIds);

            for (TasareehIntegration_Parser.cls_Professionals prof : professionals) {
                if (!mapWithExtObjRecs.containsKey(prof.RecordId)) continue;

                Professional__c obj = new Professional__c();
                obj.Permit__c = mapWithExtObjRecs.containsKey(prof.RecordId) && !isNull(prof.RecordId) ? ((Permit__c) mapWithExtObjRecs.get(prof.RecordId)).Id : null;
                obj.ConsultantTradeLicenseNumber__c = prof.ConsultantTradeLicenseNumber;
                obj.ConsultantType__c = prof.ConsultantType;
                obj.ConsultantName__c = prof.ConsultantName;
                obj.ConsultantEmail__c = !isNull(prof.ConsultantEmail) ? prof.ConsultantEmail : null;
                obj.ConsultantMobile__c = prof.ConsultantMobile;
                obj.ContractorName__c = prof.ContractorName;
                obj.ContractorMobile__c = prof.ContractorMobile;
                obj.ContractorTradeLicenseNumber__c = prof.ContractorTradeLicenseNumber;
                obj.ContractorEmail__c = !isNull(prof.ContractorEmail) ? prof.ContractorEmail : null;
                obj.StatusDate__c = DateTime.valueOf(prof.StatusDate);
                obj.ParentId__c = prof.RecordId;
                if(obj.ParentId__c != null)
                    obj.UniqueIdentfier__c = prof.RecordId +' '+ prof.ConsultantTradeLicenseNumber;
                lst.add(obj);
            }
            //UPSERT lst UniqueIdentfier__c;
            Map<String, Professional__c> mapUniqueIdProfRecords = new Map<String, Professional__c>();
            for(Professional__c profRec: lst){
                mapUniqueIdProfRecords.put(profRec.UniqueIdentfier__c, profRec);
            }
            UPSERT mapUniqueIdProfRecords.values() UniqueIdentfier__c;
        } catch (Exception ex) {
            System.debug('Error in mapProfessional: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapProfessional','TasareehIntegration_Ctrl','mapProfessional'));
        }
    }

    // Method to map status history with error handling
    public static void mapStatusHistory(TasareehIntegration_Parser.cls_StatusHistory[] statHistory) {
        List<StatusHistory__c> lst = new List<StatusHistory__c>();
        Map<String, StatusHistory__c> mapStatusHistoryCreate = new Map<String, StatusHistory__c>();
        Set<String> setUnqueIds = new Set<String>();

        try {
            for (TasareehIntegration_Parser.cls_StatusHistory hist : statHistory) {
                if (!isNull(hist.RecordId)) setUnqueIds.add(String.escapeSingleQuotes(hist.RecordId));
            }

            Map<String, Sobject> mapWithExtObjRecs = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c', 'Permit__c', 'RecordId__c', 'RecordId__c', setUnqueIds);

            for (TasareehIntegration_Parser.cls_StatusHistory hist : statHistory) {
                if (!mapWithExtObjRecs.containsKey(hist.RecordId)) continue;

                StatusHistory__c obj = new StatusHistory__c();
                obj.Name = String.valueOf(hist.StatusHistoryId);
                obj.Permit__c = mapWithExtObjRecs.containsKey(hist.RecordId) && !isNull(hist.RecordId) ? ((Permit__c) mapWithExtObjRecs.get(hist.RecordId)).Id : null;
                obj.Status__c = hist.RecordStatus;
                obj.StatusHistoryId__c = String.valueOf(hist.StatusHistoryId);
                obj.StatusDate__c = DateTime.valueOf(hist.StatusDate);
                obj.StatusComment__c = hist.StatusComment;
                obj.ServiceCode__c = hist.ServiceCode;
                obj.ParentId__c = hist.RecordId;
                lst.add(obj);
                mapStatusHistoryCreate.put(obj.StatusHistoryId__c, obj);
            }
            UPSERT mapStatusHistoryCreate.values() StatusHistoryId__c;
        } catch (Exception ex) {
            System.debug('Error in mapStatusHistory: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapStatusHistory','TasareehIntegration_Ctrl','mapStatusHistory'));
        }
    }

    // Method to map workflow tasks with error handling
    public static void mapWorkflowTask(TasareehIntegration_Parser.cls_WorkflowTasks[] tasks) {
        List<WorkflowTask__c> lst = new List<WorkflowTask__c>();
        List<TasareehIntegration_Parser.cls_WorkflowTasks> taskslst = new List<TasareehIntegration_Parser.cls_WorkflowTasks>();
        List<WorkflowTask__c> lstToDelete = new List<WorkflowTask__c>();
        Set<String> setUnqueIds = new Set<String>();

        try {
            for (TasareehIntegration_Parser.cls_WorkflowTasks task : tasks) {
                if (!isNull(task.RecordId)) setUnqueIds.add(String.escapeSingleQuotes(task.RecordId));
            }

            Map<String, Sobject> mapWithExtObjRecs = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c', 'Permit__c', 'RecordId__c', 'RecordId__c', setUnqueIds);

            for (TasareehIntegration_Parser.cls_WorkflowTasks task : tasks) {
               // if (!mapWithExtObjRecs.containsKey(task.RecordId)) continue;

                WorkflowTask__c obj = new WorkflowTask__c();
                obj.Permit__c = mapWithExtObjRecs.containsKey(task.RecordId) && !isNull(task.RecordId) ? ((Permit__c) mapWithExtObjRecs.get(task.RecordId)).Id : null;
                obj.TaskName__c = task.TaskName;
                obj.Name = obj.TaskName__c;
                obj.TaskStatus__c = !isNull(task.TaskStatus) ? task.TaskStatus : null;
                obj.DueDays__c = task.DueDays;
                obj.DueDate__c = !isNull(task.DueDate) ? Date.valueOf(task.DueDate) : null;
                obj.AssginedDate__c = !isNull(task.AssginedDate) ? DateTime.valueOf(task.AssginedDate) : null;
                obj.Status_Date__c = !isNull(task.StatusDate) ? DateTime.ValueOf(task.StatusDate) : null;
                obj.KPIInDays__c = !isNull(task.StatusDate) ? Integer.valueOf(task.KPIInDays) : null;
                obj.IsActive__c = !isNull(task.IsActive) ? task.IsActive : null;
                obj.IsCompleted__c = task.IsCompleted;
                obj.Comments__c = task.Comments;
                obj.Department__c = task.Department;
                obj.EmployeeName__c = task.EmployeeName;
                obj.EmployeeId__c = task.EmployeeId;
                obj.SequenceId__c = !isNull(task.SequenceId) ? Integer.valueOf(task.SequenceId) : null;
                obj.ParentId__c = task.RecordId;
                lst.add(obj);
                taskslst.add(task);
            }

            Set<String> permitRecIds = new Set<String>();
            Set<String> taskNameList = new Set<String>();
            for (TasareehIntegration_Parser.cls_WorkflowTasks tsk : taskslst) {
                String permitRecordId = tsk.RecordId;
                //String permitRecordId = ((Permit__c) mapWithExtObjRecs.get(tsk.RecordId)).RecordId__c;
                permitRecIds.add(permitRecordId);
                taskNameList.add(permitRecordId+'-'+tsk.TaskName);
            }

            for (WorkflowTask__c wfTask : [SELECT id, TaskName__c,ParentId__c FROM WorkflowTask__c WHERE ParentId__c IN :permitRecIds]) {
                if (taskNameList.contains(wfTask.ParentId__c+'-'+wfTask.TaskName__c)) {
                    lstToDelete.add(wfTask);
                }
            }

            if (!lstToDelete.isEmpty()) {
                DELETE lstToDelete;
            }

            if (!lst.isEmpty()) INSERT lst;
        } catch (Exception ex) {
            System.debug('Error in mapWorkflowTask: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapWorkflowTask','TasareehIntegration_Ctrl','mapWorkflowTask'));
        }
    }

    // Method to map workflow history with error handling
    public static void mapWorkflowHistory(TasareehIntegration_Parser.cls_WorkflowHistory[] WorkflowHistory) {
        List<WorkflowHistory__c> lst = new List<WorkflowHistory__c>();
        Set<String> setUnqueIds = new Set<String>();

        try {
            for (TasareehIntegration_Parser.cls_WorkflowHistory hist : WorkflowHistory) {
                if (!isNull(hist.RecordId)) setUnqueIds.add(String.escapeSingleQuotes(hist.RecordId));
            }

            Map<String, Sobject> mapWithExtObjRecs = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c', 'Permit__c', 'RecordId__c', 'RecordId__c', setUnqueIds);

            for (TasareehIntegration_Parser.cls_WorkflowHistory hist : WorkflowHistory) {
                WorkflowHistory__c obj = new WorkflowHistory__c();
                obj.Permit__c = mapWithExtObjRecs.containsKey(hist.RecordId) && !isNull(hist.RecordId) ? ((Permit__c) mapWithExtObjRecs.get(hist.RecordId)).Id : null;
                obj.TaskName__c = hist.TaskName;
                obj.Name = obj.TaskName__c;
                obj.TaskStatus__c = hist.TaskStatus;
                obj.DueInDays__c = hist.DueInDays;
                obj.TaskDueDate__c = !isNull(hist.TaskDueDate) ? Date.valueOf(hist.TaskDueDate) : null;
                obj.TaskAssignedDate__c = !isNull(hist.TaskAssignedDate) ? DateTime.valueOf(hist.TaskAssignedDate) : null;
                obj.TaskStatusDate__c = !isNull(hist.TaskStatusDate) ? DateTime.valueOf(hist.TaskStatusDate) : null;
                obj.TaskKPIInDays__c = !isNull(hist.TaskKPIInDays) ? Integer.valueOf(hist.TaskKPIInDays) : null;
                obj.IsActive__c = hist.IsActive;
                obj.IsCompleted__c = hist.IsCompleted;
                obj.Department__c = hist.Department;
                obj.EmployeeName__c = hist.EmployeeName;
                obj.EmployeeId__c = !isNull(hist.EmployeeId) ? String.valueOf(hist.EmployeeId) : null;
                obj.Id__c = !isNull(hist.Id) ? String.valueOf(hist.Id) : null;
                obj.ParentId__c = hist.RecordId;
                
                lst.add(obj);
            }
            INSERT lst;
        } catch (Exception ex) {
            System.debug('Error in mapWorkflowHistory: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapWorkflowHistory','TasareehIntegration_Ctrl','mapWorkflowHistory'));
        }
    }
    // Method to map Payment
    public static void mapPayments(TasareehIntegration_Parser.cls_paymentRequest[] arrPayment){
        Set<String> setIds = new Set<String>();
        try{
            for(TasareehIntegration_Parser.cls_paymentRequest payment : arrPayment){
                if(!isNull(payment.RecordId))
                    setIds.add(String.escapeSingleQuotes(payment.RecordId));
            }
           
            Map<String,Sobject> mapWithExtObjRecs = TasareehIntegration_Util.mapWithExtObjRecs('Name,RecordId__c','Permit__c','RecordId__c','RecordId__c',setIds);
            
            List<Permit_Payment__c> lstPayment = new List<Permit_Payment__c>();
            for(TasareehIntegration_Parser.cls_paymentRequest payment :arrPayment){
                Permit_Payment__c obj = new Permit_Payment__c(); 
                obj.Permit__c = (mapWithExtObjRecs.containsKey(payment.RecordId) && !isNull(payment.RecordId)? ((Permit__c)mapWithExtObjRecs.get(payment.RecordId)).Id : null);
                obj.FeeDescription__c = payment.FeesDescription;
                obj.Payment_Date__c = (!isNull(payment.PaymentDate)   ? Datetime.valueOf(payment.PaymentDate) : obj.Payment_Date__c);
                obj.FeeCode__c=payment.FeesCode;
                obj.InvoiceNumber__c = payment.InvoiceNBR;
                obj.Payment_Amount__c = (!isNull(payment.Amount) && payment.Amount > 0 ? payment.Amount : obj.Payment_Amount__c);	
               	obj.PaymentIdentifier__c= payment.FeesDescription+'-'+payment.InvoiceNBR;
                obj.PermitSubmissionDate__c = (!isNull(payment.RecordSubmissionDate) ? DateTime.valueOf(payment.RecordSubmissionDate) : null) ; 
                obj.FeeSchedule__c = payment.gf_fee_schedule;
                obj.Transaction_Code__c = (!isNull(payment.TransactionCode) ? payment.TransactionCode : null);
                obj.Request_Type__c = (!isNull(payment.RecordRequestType) ? payment.RecordRequestType : null);
                obj.PaymentMethod__c =payment.PaymentMethod;
                obj.ParentId__c = payment.RecordId;
                lstPayment.add(obj);
            }
            //UPSERT lstFees RecordId__c;
            
            Database.UpsertResult[] results = Database.upsert(lstPayment, Permit_Payment__c.PaymentIdentifier__c, false);
            List<Permit_Payment__c> lstPaymentToBeUpsert = new List<Permit_Payment__c>();
            Map<String, Permit_Payment__c> mapPaymentToBeUpsert = new Map<String, Permit_Payment__c>();

            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult upsertResultValue = results[i];
                for (Database.Error err : upsertResultValue.getErrors()) {
                    mapPaymentToBeUpsert.put(lstPaymentToBeUpsert[i].PaymentIdentifier__c,lstPaymentToBeUpsert[i]);
                }
            }

            if (!mapPaymentToBeUpsert.values().isEmpty()) {
                UPSERT mapPaymentToBeUpsert.values() PaymentIdentifier__c;
            }
        }catch (DmlException ex) {
            System.debug('Error in mapFees: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapPayments','TasareehIntegration_Ctrl','mapPayments'));
        }
    }

    // Utility method to check if a value is null
    public static boolean isNull(Object value){
        if (value instanceof String) {
            if(String.isBlank((String)value))
                return true;
            if(String.valueOf(value).toLowercase() == 'null' || String.valueOf(value).toLowercase() == 'na')
                return true;
        }
        return value == null;
    }
    
    // Utility method to remove null from value
    public static string removeNull(String val){
        if(!String.isBlank(val))
            return val;
        return '';
    }
    
    // Utility method to remove Commas from value
    public static string removeCommas(String val){
        if(val.contains(',')){
            val = val.replaceAll(',', '');
        }
        if(val.contains(' ')){
            val = val.replaceAll(' ', '');
        }
            return val;
    }
    
    
    // Utility method to check if Alphabetic in input value
    public static Boolean checkIfAlphabetic(String input) {
        if (input != null && Pattern.matches('.*[a-zA-Z].*', input)) {
            return true;
        }
        return input == null;
    }
    
}