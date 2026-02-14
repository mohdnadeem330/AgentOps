@RestResource (urlMapping = '/query/salesofferdetails')
global with sharing class SalesOfferWebService {

    public static Boolean isRunningTest = false ;

    @HTTPPost
    global static void doPost(){

        RestContextHandler handler = new RestContextHandler(true);
        

        try {

            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            BookingDetailModel offerDetail = (BookingDetailModel)JSON.deserializeStrict(jsonBody,BookingDetailModel.class);

system.debug('outside');            
            
            
            if(offerDetail.sendEmail !=null && offerDetail.sendEmail){
                system.debug('emailistrue');
                if(offerDetail.opportunityId !=null){
                    if(!isRunningTest)
                    system.debug('Inside If');
                    OpportunityUnitSearchController.sendSalesOfferPDF(offerDetail.inputWrapperList,offerDetail.opportunityId, offerDetail.customerName,offerDetail.offerUnitId);

                    handler.response.message = Constants.EMAIL_SENT_SUCCESSFULLY ;
                    handler.response.success = true;
                }
                else{
                    handler.response.success = false;
                    handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                    handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
                }
            }              
            else{
                List<SalesOfferResponseModel> salesOfferResponse = new List<SalesOfferResponseModel>();

                String offerBaseURL = Utilities.getVFDomainURL() ;

                String unitIds ;
                for(Id unitId : offerDetail.unitIds){
                    unitIds = unitId + (unitIds!=null ? '|' + unitIds : '');
                }

                Map<id,Unit__c> unitDetailMap = new Map<id,Unit__c>( UnitService.getAllUnitsById(offerDetail.unitIds));

                for(SalesOfferUtility.SaleOfferInputParam salesOfferInput : offerDetail.inputWrapperList){

                    String paymentPlanIds;
                    for(Id paymentPlanId : salesOfferInput.selectedPayments){
                        paymentPlanIds = paymentPlanId + (paymentPlanIds!=null ? '|' + paymentPlanIds : '');
                    }

                    PageReference pdf = Page.OfferDetailsPDF;
                    pdf.getParameters().put('id',(offerDetail.opportunityId!=null || offerDetail.opportunityId!=''? offerDetail.opportunityId:null));
                    pdf.getParameters().put('currentUnit',salesOfferInput.unitId);
                    pdf.getParameters().put('otherUnits',unitIds);
                    pdf.getParameters().put('currentOffer',salesOfferInput.offerId);
                    pdf.getParameters().put('selectedPayments',paymentPlanIds);
                    pdf.getParameters().put('PODSelection',salesOfferInput.podiumSelection);
                    // swimming pool changes for yas riva
                    pdf.getParameters().put('swimmingPoolSelection',salesOfferInput.swimmingPoolSelection);
                    pdf.getParameters().put('multiPurposeAmount',string.ValueOf(salesOfferInput.multiPurposeAmountApplicable));
                    pdf.getParameters().put('selectedDesign',string.ValueOf(salesOfferInput.designId));
                    pdf.getParameters().put('customerName',(offerDetail.customerName!=null?offerDetail.customerName:''));
                    pdf.setRedirect(true);
    
                    Blob fileContent ;
                    if(!isRunningTest)
                        fileContent = pdf.getContent();
                    String fileName ='Offer-'+unitDetailMap.get(salesOfferInput.unitId).Name+'-'+offerDetail.customerName+'-'+System.now().format('dd-MM-yyyy')+'.pdf' ;

                    String offerURL = offerBaseURL + '/apex/OfferDetailsPDF?id='+salesOfferInput.unitId+'&currentUnit='+salesOfferInput.unitId+'&currentOffer='+salesOfferInput.offerId+'&otherUnits='+unitIds+'&selectedPayments='+paymentPlanIds+'&customerName='+offerDetail.customerName+'&multiPurposeAmount='+salesOfferInput.multiPurposeAmountApplicable+'&affectionPlan='+offerDetail.affectionPlan+'&marketingPlan='+offerDetail.marketingPlan;
                    
                    salesOfferResponse.add(new SalesOfferResponseModel(salesOfferInput.unitId,offerURL,new DocumentQueryModel('application/pdf',fileContent,fileName)));
                }
                handler.response.data = salesOfferResponse;
                handler.response.success = true;
            }            
            handler.finalize();
        }catch (Exception exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }

    }

    global class SalesOfferResponseModel{
        public Id  unitId ;
        public String  salesofferURL ;
        public DocumentQueryModel fileDetail ;

        public SalesOfferResponseModel(Id unitId,String url,DocumentQueryModel fileDetail){
            this.unitId = unitId ;
            this.salesofferURL = url ;
            this.fileDetail = fileDetail ;
        }
    }
}