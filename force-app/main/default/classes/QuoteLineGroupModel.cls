public class QuoteLineGroupModel {
    public SBQQ__QuoteLineGroup__c record;
    public Decimal netNonSegmentTotal;
    public Integer key;
    public QuoteModel parse(String json) {
        return (QuoteModel) System.JSON.deserialize(json, QuoteModel.class);
    }
}