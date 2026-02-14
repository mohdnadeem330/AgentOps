/**
* @File Name : PremPark_OrderIntegrationUtils.cls
* @Description :
* @Author : Harsh@Aldar
* @Last Modified By :
* @Last Modified On : October 15, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 15, 2024 | Harsh@Aldar | Initial Version
**/

public class PremPark_OrderIntegrationUtils {
	
	public static Map<Id, Order> getWholeOrderAsMap(Set<Id> orderIdSet) {
		// Initialize the map to hold orders
		Map<Id, Order> orderMap = new Map<Id, Order>();

		// Query to get orders along with their order items
		List<Order> orders = [
			SELECT Id, TotalAmount, Status, SBQQ__Quote__r.Sales_Order__c, AccountId, Account.ERPID__c,
				(SELECT Id, Product2.Name, Product2Id, Quantity, Order.Id, SBQQ__QuotedListPrice__c, TotalPrice, UnitPrice
				FROM OrderItems)
			FROM Order
			WHERE Id IN :orderIdSet
		];

		// Populate the map with the queried orders
		for (Order order : orders) {
			orderMap.put(order.Id, order);
		}

		return orderMap;
	}

	public static Map<Id, ReceiptAcknowledgement__c> getWholeReceiptAsMap(Set<Id> recordIdSet) {
		// Initialize the map to hold orders
		Map<Id, ReceiptAcknowledgement__c> recordMap = new Map<Id, ReceiptAcknowledgement__c>();

		// Query to get ReceiptAcknowledgement__c
		List<ReceiptAcknowledgement__c> records = [
			SELECT Id, Name, SalesOrder__c, SalesOrder__r.Name, Order__c, Amount__c, 
			SalesOrder__r.Unit__r.Name, Order__r.SBQQ__Quote__r.Parking_Ref_ID__c,
			ReceiptDate__c, ChequeReceived__c, Remarks__c, ChequeReceivedDate__c, ChequeReceivedBy__r.Email,
			PaymentType__c, BankName__c, CurrencyIsoCode, Createdby.Email, Status__c, SalesOrder__r.ERPID__c
			FROM ReceiptAcknowledgement__c
			WHERE Id IN :recordIdSet
		];

		// Populate the map with the queried orders
		for (ReceiptAcknowledgement__c record : records) {
			recordMap.put(record.Id, record);
		}

		return recordMap;
	}

}