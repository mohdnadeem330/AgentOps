@isTest
public class QuoteModelTest {
	@isTest
    public static void test(){
         QuoteModel quoteModel = new QuoteModel();
            quoteModel.record =null;
        quoteModel.nextKey = 1;
        quoteModel.applyAdditionalDiscountLast = true;
        quoteModel.applyPartnerDiscountFirst = false;
        quoteModel.channelDiscountsOffList = true;
        quoteModel.customerTotal = 5000;
        quoteModel.netTotal = 4500;
        quoteModel.netNonSegmentTotal = 4000;
        quoteModel.lineItems = new List<QuoteLineModel>();
        quoteModel.lineItemGroups = new List<QuoteLineGroupModel>();
        QuoteModel.parse(JSON.serialize(quoteModel));
        QuoteLineGroupModel qt = new QuoteLineGroupModel();
        qt.parse(JSON.serialize(quoteModel));
        QuoteLineModel ql = new QuoteLineModel();
        ql.parse(JSON.serialize(quoteModel));
    }
}