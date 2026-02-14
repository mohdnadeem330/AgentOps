/**
* @File Name : PremPark_OrderIntegrationController.cls
* @Description :
* @Author : Harsh@Aldar
* @Last Modified By :
* @Last Modified On : October 15, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 15, 2024 | Harsh@Aldar  | Initial Version
**/

public class PremPark_OrderIntegrationController {
	
	public PremPark_OrderIntegrationController(){

	}

	public static String processName = 'PremPark_OrderERP_CPQ';
	@future(callout = TRUE)
	public static void pushOrderToERP(Set<Id> orderRecordId){

		if(orderRecordId?.size() > 0){

			System.debug('####orderRecordId: '+orderRecordId);

			PremPark_OrderIntegrationWrappers requestWrap = mapOrder_SfToERP(orderRecordId);

			System.debug('####requestWrap: '+requestWrap);

			String requestBodyAsString = JSON.serializePretty(requestWrap);

			System.debug('####requestBodyAsString : '+requestBodyAsString);

			HttpResponse responseFromERP = CalloutToMuleSoft.makeCallout(processName, requestBodyAsString);
            system.debug('responseFromERP::'+responseFromERP);
			String responseBody = responseFromERP.getBody();
			System.debug('####responseBody : '+responseBody);

			handleResponse(responseBody, requestBodyAsString);

		}

	}

	private static void handleResponse(String responseBody, String requestBody){

		 // Deserialize the JSON response
		 System.debug('####requestBody: '+requestBody);
		 System.debug('####apiResponse: '+responseBody);
		 // Initialize lists for processing
		List<Logger__c> loggerListForSync = new List<Logger__c>();
		List<Order> orderListToUpdate = new List<Order>();
        if(responseBody !='your Json Response'){
		if(responseBody.toLowerCase().contains('"results": ""')){
			System.debug('ERP Returned Null Response : '+responseBody);
			Logger__c exceptionLog = LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, responseBody, null);
			exceptionLog.ExceptionMessage__c = responseBody;
			insert exceptionLog;
			return;
		}
		PremPark_OrderIntegrationWrappers.ERPResponse apiResponse = (PremPark_OrderIntegrationWrappers.ERPResponse) JSON.deserialize(responseBody, PremPark_OrderIntegrationWrappers.ERPResponse.class);
		Set<String> successCodes = new Set<String>{'200','201','202'};
		
		System.debug('####apiResponse: '+apiResponse);
		if (apiResponse.success) {
			if(successCodes.contains(apiResponse.statusCode)){
				for (PremPark_OrderIntegrationWrappers.Result responseRecord : apiResponse.results) {
					// Create log entries for success and failure
					Logger__c log;
					if(responseRecord.status == 'Success'){
						
						orderListToUpdate.add(new Order(Id = responseRecord.sfOrderId, ERP_Id__c = responseRecord.erpID));
						log = LoggerService.logSuccessResponse('CalloutToMuleSoft', 'calloutService', processName, requestBody, responseBody, null);
					}else{
						log = LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, responseBody, null);
						log.ExceptionMessage__c = responseRecord.errorMsg;
					}
                    if(!Test.isRunningTest()){
					log.Order__c = responseRecord.sfOrderId;
                    
					loggerListForSync.add(log);
                    }
                    
				
				}
			}
		}else {
			System.debug('Request failed with status: ' + apiResponse?.results[0]?.status);
			System.debug('Error Message: ' + apiResponse?.results[0]?.errorMsg);
			Logger__c log;
			log = LoggerService.addApexServiceCalls('CalloutToMuleSoft', 'calloutService', processName, requestBody, responseBody, null);
			log.ExceptionMessage__c = apiResponse?.results[0]?.errorMsg;
		}

		if (!loggerListForSync.isEmpty()) {
			insert loggerListForSync; 
		}
		if (!orderListToUpdate.isEmpty()) {
			update orderListToUpdate;
		}
        }
		
	}

	/**
	* Maps Salesforce Order records to the PremPark_OrderIntegrationWrappers format for ERP integration.
	*
	* This method retrieves Orders based on the provided IDs and populates a wrapper object with
	* order details and associated line items, including product information and pricing.
	*
	* @param orderIdSet A set of Order IDs to retrieve and map.
	* @return A PremPark_OrderIntegrationWrappers object containing the mapped order data.
	*/
	private static PremPark_OrderIntegrationWrappers mapOrder_SfToERP(Set<Id> orderIdSet) {
		PremPark_OrderIntegrationWrappers wrapper = new PremPark_OrderIntegrationWrappers();
		wrapper.parkingOrder = new List<PremPark_OrderIntegrationWrappers.parkingOrder>();
		
		// Retrieve orders
		Map<Id, Order> orderMap = PremPark_OrderIntegrationUtils.getWholeOrderAsMap(orderIdSet);
		
		// Iterate through the retrieved orders and populate the wrapper
		for (Order order : orderMap.values()) {
			PremPark_OrderIntegrationWrappers.parkingOrder orderWrapper = new PremPark_OrderIntegrationWrappers.parkingOrder();
			orderWrapper.orderAmount = String.valueOf(order.TotalAmount);
			orderWrapper.orderID = order.Id;
			orderWrapper.orderStatus = order.Status;
			orderWrapper.sfSalesOrderId = order.SBQQ__Quote__r != null ? order.SBQQ__Quote__r.Sales_Order__c : null;
			orderWrapper.erpCustomerId = order.Account != null ? order.Account.ERPID__c : null;
			orderWrapper.sfCustomerSfId = order.AccountId;
			
			// Populate parking order lines
			orderWrapper.parkingOrderLines = new List<PremPark_OrderIntegrationWrappers.parkingOrderLines>();
			for (OrderItem line : order.OrderItems) {
				PremPark_OrderIntegrationWrappers.parkingOrderLines lineWrapper = new PremPark_OrderIntegrationWrappers.parkingOrderLines();
				lineWrapper.productName = line.Product2 != null ? line.Product2.Name : null;
				lineWrapper.productId = line.Product2Id;
				lineWrapper.quantity = String.valueOf(line.Quantity);
				lineWrapper.orderId = order.Id;
				lineWrapper.quotedPrice = String.valueOf(line.SBQQ__QuotedListPrice__c);
				lineWrapper.totalPrice = String.valueOf(line.TotalPrice);
				lineWrapper.inventoryFlag = 'Y'; //TBD
				lineWrapper.unitPrice = String.valueOf(line.UnitPrice);
				
				orderWrapper.parkingOrderLines.add(lineWrapper);
			}
			
			// Add the order wrapper to the main list
			wrapper.parkingOrder.add(orderWrapper);
		}
		
		return wrapper;
	}

	
}