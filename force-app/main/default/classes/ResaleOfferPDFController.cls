/**********************************************************************************************************************
* Name               : ResaleOfferPDFController                                                        
* Description        : This class is used to generate the PDF for Resale Offer
* Usage              : ResaleOfferPDF VF Page                                                          
* Created By         : Harsh@Aldar                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     27 July 2023      Initial Draft       
******************************************************************************************************************/
public without sharing class ResaleOfferPDFController {
    public ResaleOfferPDFUtility.SalesOfferDetails offerDetails {get; set;}
    public string todayDate {get; set;}
    public string randomString {get; set;}
    public string customerName {get; set;}
    public String currentUnit {get; set;}
    public String opportunityId {get; set;}
    public Double admFee {get; set;}
    public Double municipalityFeePercentage {get; set;} //ASF-3650
     public List<String> activeMunicipalityCities { get; set; }
    public Boolean isCityActive { get; set; } 

    public ResaleOfferPDFController(){
        currentUnit = ApexPages.currentPage().getParameters().get('currentUnit');
        customerName = ApexPages.currentPage().getParameters().get('customerName');
        opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
        
        if(currentUnit!=null && currentUnit!=''){
            
            randomString = generateRandomString(7);
            offerDetails = getData(currentUnit, opportunityId);
			 // ASF-3400 changes
            //KP: Municipality Fee details from custom metadata
           activeMunicipalityCities =new List<String>();
            Map<String, Municipality_Fee_Details__mdt> mfdByCountryMap = new Map<String, Municipality_Fee_Details__mdt>();
            for(Municipality_Fee_Details__mdt mfd : Municipality_Fee_Details__mdt.getAll().values()){
                if(mfd.isActive__c){
                    mfdByCountryMap.put(mfd.City__c, mfd);
                    activeMunicipalityCities.add(mfd.City__c);
                }
            }
             isCityActive = activeMunicipalityCities != null && activeMunicipalityCities.contains(offerDetails.unitRecord.Project__r.City__c);
            admFee = Double.valueof(mfdByCountryMap.get(offerDetails.unitRecord.Project__r.City__c).Municipality_Charge__c);
            todayDate = System.today().format();System.debug(offerDetails.unitRecord.PropertyId__c);
            //ASF-3650
            municipalityFeePercentage = Double.valueof(mfdByCountryMap.get(offerDetails.unitRecord.Project__r.City__c).Municipality_Fee_perc__c);
            string fileName = 'Offer-'+offerDetails.unitRecord.PropertyId__c+'-'+customerName+'-'+todayDate;
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename='+fileName+'.pdf');System.debug(JSON.serializePretty(offerDetails));
        }
        
    }

    private static ResaleOfferPDFUtility.SalesOfferDetails getData(Id unitId, Id opportunityId){
        if(!String.isBlank(unitId) && !String.isBlank(opportunityId)){
            ResaleOfferPDFUtility.SalesOfferDetails returnWrap = new ResaleOfferPDFUtility.SalesOfferDetails();

            Unit__c thisUnit = [SELECT Id, Name, Project__r.Name, CompletionDate__c, UnitType__c, TotalArea__c, TerraceArea__c, 
                                UnitModel__c, Listing_Price__c, PropertyId__c, CurrencyISOCode,
                                ListedCase__c, ListedCase__r.SalesOrder__c, Project__r.City__c,
                                Project__c, Project__r.BeneficiaryNameCorporate__c, Project__r.BeneficiaryNameEscrow__c,CommunityName__c 
                                FROM Unit__c 
                                WHERE Id =: unitId
                                LIMIT 1];
            returnWrap.unitRecord = thisUnit;
            returnWrap.listingPrice = (thisUnit.Listing_Price__c).setScale(2);

            List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id =: opportunityId];
            Opportunity thisOpp = opps != null && !opps.isEmpty() ? opps[0]: new Opportunity();
            returnWrap.opportunityRecord = thisOpp;

            if(thisUnit?.ListedCase__r?.SalesOrder__c == null){
                return returnWrap;
            }
            SalesOrder__c thisSalesOrder = [SELECT Id, TotalBilled__c, SellingPrice__c
                                            FROM SalesOrder__c
                                            WHERE Id =: thisUnit.ListedCase__r.SalesOrder__c
                                            LIMIT 1];

            List<InstallmentLines__c> theInstallmentLines = [SELECT Id, InstallmentNumber__c, InvoiceNumber__c, InstallmentPercentage__c, 
                                                        InstallmentDate__c, InstallmentAmount__c, AmountReceived__c, 
                                                        OutstandingAmount__c, Description__c 
                                                        FROM InstallmentLines__c 
                                                        WHERE SalesOrder__c =: thisSalesOrder.Id
                                                        // AND OutstandingAmount__c > 0
                                                        ORDER BY InstallmentNumber__c];
            
            
			
            //amount calculations
            //line wise breakup described in the wrapper class
            returnWrap.originalPrice = (thisSalesOrder.SellingPrice__c).setScale(2);
            returnWrap.totalAmountPaidTillDate = (thisSalesOrder.TotalBilled__c).setScale(2);
            returnWrap.percentPaidTillDate = ((returnWrap.totalAmountPaidTillDate / returnWrap.originalPrice) * 100).setScale(2);
            returnWrap.outstandingAmount = (returnWrap.originalPrice - returnWrap.totalAmountPaidTillDate).setScale(2);
             // ASF-3400 changes
            //KP: Municipality Fee details from custom metadata
            Map<String, Municipality_Fee_Details__mdt> mfdByCountryMap = new Map<String, Municipality_Fee_Details__mdt>();
            for(Municipality_Fee_Details__mdt mfd : Municipality_Fee_Details__mdt.getAll().values()){
                if(mfd.isActive__c){
                    mfdByCountryMap.put(mfd.City__c, mfd);
                }
            }
            returnWrap.admFee = ((returnWrap.originalPrice * 0.02 ) + Double.valueof(mfdByCountryMap.get(thisUnit.Project__r.City__c).Municipality_Charge__c)).setScale(2); //ASF-3400
            returnWrap.transferAdminFee = 3969.00;
            returnWrap.agencyFee = (returnWrap.listingPrice * 0.02).setScale(2);
            returnWrap.totalPayByBuyer = (returnWrap.listingPrice + returnWrap.admFee + returnWrap.transferAdminFee + returnWrap.agencyFee).setScale(2);
            returnWrap.payableToSeller = ((returnWrap.listingPrice - returnWrap.originalPrice) + returnWrap.totalAmountPaidTillDate).setScale(2);
            returnWrap.payableToAldar = (returnWrap.outstandingAmount + returnWrap.agencyFee).setScale(2);
            returnWrap.installmentLinesList = (new ResaleOfferPDFUtility.InstallmentLinesWrapper(theInstallmentLines)).installmentLines;

            return returnWrap;
        }
        return null;
    }
    
    /**
    * createPublickLink 
    *
    * Create public link for the Floor plan if not available 
    * 
    * @usage OfferDetailsPDF VF page
    *
    * @param none
    * @return none
    * 
    */
    public  void createPublickLink(){
        String currentUnit = ApexPages.currentPage().getParameters().get('currentUnit');
    }
    
    /**
    * generateRandomString 
    *
    * generate random string for offer letter
    * 
    * @usage OfferDetailsPDF VF page
    *
    * @param len number of random characters
    * @return String random string
    * 
    */
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

    /**
    * createContentDistribution
    *
    * This method used to create ContentDistribution object
    *
    * @param  contentVersionId 
    * @param  CaseID 
    * @return ContentDistribution
    */
    public static ContentDistribution createContentDistribution(Id contentVersionId,Id unitID , string fileName){
        ContentDistribution newDist = new ContentDistribution();
        newDist.ContentVersionId = contentVersionId;
        newDist.Name = fileName;
        newDist.PreferencesNotifyOnVisit = false;
        newDist.PreferencesAllowViewInBrowser = true;
        newDist.PreferencesAllowOriginalDownload=true;
        newDist.RelatedRecordId= unitID;
        return newDist;
    }
    
   
}