@isTest
private class LtngQuickStepTransitionWrapperTest {
    
    @isTest static  void fillWrapper() {
        LtngQuickStepTransitionWrapper ltng = new LtngQuickStepTransitionWrapper();

        ltng.caseOfficerId = '';
        ltng.caseOfficerName = '';
        ltng.userType = '';
        ltng.payeeType = '';
        ltng.errorMessage = '';
        ltng.rawSOQL = '';
        ltng.rawQueueSOQL = '';
        ltng.lookUpLabel = '';
        ltng.availableValues = new Map<String, String>();
        ltng.objFormSection.SectionName = '';

        LtngQuickStepTransitionWrapper.FormObjectsWrapper form = new LtngQuickStepTransitionWrapper.FormObjectsWrapper();
        form.FormId = '';
        form.ObjectApi = '';
        form.SectionFields = new list<LtngQuickStepTransitionWrapper.FormFieldsWrapper>();
        form.sObjectId = '';

        LtngQuickStepTransitionWrapper.FormFieldsWrapper filed = new LtngQuickStepTransitionWrapper.FormFieldsWrapper();
        filed.ObjectApi = '';
        filed.FieldApi = '';
        filed.FieldType = '';
        filed.FieldValue = null;
        filed.LookupValue = null;
        filed.isRendered = true;


    }
}