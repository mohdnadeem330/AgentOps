public class RETL_OrderItemHelper {

    public static void updateUnitNumbers(List<OrderItem> newList, List<OrderItem> oldList) {
        Set<Id> orderIds = new Set<Id>();
		Id rtId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Retail_lease').getRecordTypeId();
        //Without SOQL
        if (newList != null) {
            for (OrderItem oi : newList) {
                orderIds.add(oi.OrderId);
            }
        }

        if (oldList != null) {
            for (OrderItem oi : oldList) {
                orderIds.add(oi.OrderId);
            }
        }

        if (orderIds.isEmpty()) return;

        // Query all related OrderItems with ProductCode
        List<OrderItem> allItems = [
            SELECT Id, OrderId, Product2.ProductCode, Order.RecordTypeId
            FROM OrderItem
            WHERE OrderId IN :orderIds AND Order.RecordTypeId = :rtId
        ];

        // Build map: OrderId → list of product codes
        Map<Id, List<String>> orderToCodesList = new Map<Id, List<String>>();
        for (Id oid : orderIds) {
            orderToCodesList.put(oid, new List<String>());
        }

        for (OrderItem oi : allItems) {
            String code = oi.Product2.ProductCode;
            if (code != null) {
                orderToCodesList.get(oi.OrderId).add(code);
            }
        }

        // Convert list to comma-separated strings
        List<Order> orderUpdates = new List<Order>();
        for (Id oid : orderIds) {
            List<String> codes = orderToCodesList.get(oid);

            orderUpdates.add(new Order(
                Id = oid,
                Unit_Number__c = (codes.isEmpty() ? null : String.join(codes, ', '))
            ));
        }

        // Update Orders
        if (!orderUpdates.isEmpty()) {
            update orderUpdates;
        }
    }
}