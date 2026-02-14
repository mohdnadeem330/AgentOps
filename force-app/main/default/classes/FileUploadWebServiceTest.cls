/*
*Created By     : Pavithra Gajendra
*Created Date   : 28/07/2022
*Description    : Test class for FileUploadWebService
*/
@isTest
private class FileUploadWebServiceTest {
    
    static testmethod void testUpload() {

        Test.startTest();
        Account accountRec = TestObjectsFactory.getPersonAccountRecord();
        insert accountRec ; 

        FileUploadModel fileWrapper = new FileUploadModel();
        fileWrapper.accountId = accountRec.Id ;
        fileWrapper.documentType = accountRec.Id ;
        fileWrapper.isPersonAccount = true ;
        fileWrapper.fileTitle = 'KYC';
        fileWrapper.fileData = Blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAAZAAAAGQCAYAAACAvzbMAAAAAXNSR0IArs4c6QAAIABJREFUeF7t3QeYVPXVx/EDUqQXFaVIEVFsGFFiAd7Y0dh9bIiIXYMG5XktsUUi9o4RKxoQLAi2GMCGsWEsEcFKsLAiJYJ0aUt7n3P3nWV22N25M9x7ZubM9z5PHpS98z/3fM64v9x7p9TYsGHDBmFDAAEEEEAgQ4EaBEiGYuyOAAIIIBAIECA8ERBAAAEEshIgQLJi40EIIIAAAgQIzwEEEEAAgawECJCs2HgQAggggAABwnNgE4HvFi2X7xctl+Vr1hWcTr1aW0j7pvVl5+YNpGaNGvEef+likW/uEPlhuMjKufHWynb1Ok1F2p4i0nmgSOPO2a7C4xCoVIAA4YlRLrC8dK18PHexLFq1puBVNEj2adlEtqlfN55eZr8i8sGZImsWx7N+HKt2GyrSqX8cK7NmkQoQIEU6+MrafnfmAvllZakbEQ2RIzu2iL6f0gUiL3cUWbMk+rXjXvGw90S26RF3FdYvEgECpEgGna7NWUtXBmcf3rbdtm4kO2/VMNq2PrtC5Ju7ol3TarVWR4ocON6qGnWcCxAgzgcctr0PZi2U/y5fHXb3gtmvYZ1acniHbaI93rHNRUoXRbum5WrHlYg0aGdZkVpOBQgQp4PNtK23Sn6RxasL/95Hat9b1Kwhx3XaLlOOqvdfu0LkuQbRrZeLlQ6bJLLNAbmoTE1nAgSIs4Fm2w4BElKOAAkJxW7FIECAFMOUQ/RIgIRA0l0IkJBQ7FYMAgRIMUw5RI8ESAgkAiQkErsViwABUiyTTtMnARLyicAZSEgodisGAQKkGKYcokcCJAQSZyAhkditWAQIkGKZdExnIO++8oK8/PiD8r/3PiKtOnQsrzLmwXuDfz65/8BqK0+b/InovpfdNVQaNW0W+TRy/Sqs/8wVOfV+kakzK7Y2qr9In+6RtxtuQV6FFc6JvdIKECBpiYpjh2zOQEpXrZJn/1r2hrr2nXeV/znmRAIk5emiATJghMj9/UR2bln2w0SoDD1bpPtO1T+/npok8t5/RO49Q6RenYieiwRIRJAsQ4DwHAgEsgkQPXt45+Wxsl+vo+TvTzxc4SyiUM9ASkpKpH379lU/KzK8B1JZgOinxQwcJdJz5/RnIQQI/4HmswABks/TMTy2bAJEQ2Lb7dvJXj0Pkvsuvzi4XNW5a7fgqJMDRP955fLlsvLXZfL66JHymx4HlodN4hKW/t3w2wYFj730zgfKz2bmzPhe7h54oZRM+zr42WkDrkh7WSyZLZtLWGeffba0a9dOBg0qO54KWwQBUlmoaFCc8WBZpQsPKTvjmFwi0uMvFf9O/03D55GJZX/fq4vIUxeLZPRpLZyBGP6X5bsUAeJ7vqG7yzRAli1eJMMGXyOnXnJ5cO9D74X8/NOP5b/cUwPk2fvvlJuffjkIGP3Zwp//K2df/Rf54esv5NrTjysPDQ2Ux268OrinsnXL1vK3W2+Q3x13UvA4DZNhN10n5113U4X7LdU1mU2A6FlIhw4dgmU1RG644YaNJbIIkMrugbx/w8bLV5Omiwx+cWMQ6D/rdv0JIqlnIPrvP8wr+1kmZzIVjAiQ0P9dsGP1AgQIz5BAINMA0V/0X3z4fnlg6C/30Q/cJeddf0twMzw1QBKBUWfLLSsEwdJFCyvcRK8uJJLDJfmGfdQBouvpWcjw4cPLl9YQCc5IsgiQ1HsgC34V6TNUpG=');

        TestObjectsFactory.initializeRestContext(null, '/file/upload');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(fileWrapper));
        FileUploadWebService.doPost();
        Test.stopTest();
    }

    static testmethod void testSOUpload() {

        Test.startTest();
       SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderData(false, '0044');

       Document__c document = TestObjectsFactory.getSalesOrderDocument(salesOrder.Opportunity__c, salesOrder.Id);
       insert document;

        FileUploadModel fileWrapper = new FileUploadModel();
        fileWrapper.documentId = document.Id ;
        fileWrapper.fileTitle = 'Signed KYC';
        fileWrapper.fileData = Blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAAZAAAAGQCAYAAACAvzbMAAAAAXNSR0IArs4c6QAAIABJREFUeF7t3QeYVPXVx/EDUqQXFaVIEVFsGFFiAd7Y0dh9bIiIXYMG5XktsUUi9o4RKxoQLAi2GMCGsWEsEcFKsLAiJYJ0aUt7n3P3nWV22N25M9x7ZubM9z5PHpS98z/3fM64v9x7p9TYsGHDBmFDAAEEEEAgQ4EaBEiGYuyOAAIIIBAIECA8ERBAAAEEshIgQLJi40EIIIAAAgQIzwEEEEAAgawECJCs2HgQAggggAABwnNgE4HvFi2X7xctl+Vr1hWcTr1aW0j7pvVl5+YNpGaNGvEef+likW/uEPlhuMjKufHWynb1Ok1F2p4i0nmgSOPO2a7C4xCoVIAA4YlRLrC8dK18PHexLFq1puBVNEj2adlEtqlfN55eZr8i8sGZImsWx7N+HKt2GyrSqX8cK7NmkQoQIEU6+MrafnfmAvllZakbEQ2RIzu2iL6f0gUiL3cUWbMk+rXjXvGw90S26RF3FdYvEgECpEgGna7NWUtXBmcf3rbdtm4kO2/VMNq2PrtC5Ju7ol3TarVWR4ocON6qGnWcCxAgzgcctr0PZi2U/y5fHXb3gtmvYZ1acniHbaI93rHNRUoXRbum5WrHlYg0aGdZkVpOBQgQp4PNtK23Sn6RxasL/95Hat9b1Kwhx3XaLlOOqvdfu0LkuQbRrZeLlQ6bJLLNAbmoTE1nAgSIs4Fm2w4BElKOAAkJxW7FIECAFMOUQ/RIgIRA0l0IkJBQ7FYMAgRIMUw5RI8ESAgkAiQkErsViwABUiyTTtMnARLyicAZSEgodisGAQKkGKYcokcCJAQSZyAhkditWAQIkGKZdExnIO++8oK8/PiD8r/3PiKtOnQsrzLmwXuDfz65/8BqK0+b/InovpfdNVQaNW0W+TRy/Sqs/8wVOfV+kakzK7Y2qr9In+6RtxtuQV6FFc6JvdIKECBpiYpjh2zOQEpXrZJn/1r2hrr2nXeV/znmRAIk5emiATJghMj9/UR2bln2w0SoDD1bpPtO1T+/npok8t5/RO49Q6RenYieiwRIRJAsQ4DwHAgEsgkQPXt45+Wxsl+vo+TvTzxc4SyiUM9ASkpKpH379lU/KzK8B1JZgOinxQwcJdJz5/RnIQQI/4HmswABks/TMTy2bAJEQ2Lb7dvJXj0Pkvsuvzi4XNW5a7fgqJMDRP955fLlsvLXZfL66JHymx4HlodN4hKW/t3w2wYFj730zgfKz2bmzPhe7h54oZRM+zr42WkDrkh7WSyZLZtLWGeffba0a9dOBg0qO54KWwQBUlmoaFCc8WBZpQsPKTvjmFwi0uMvFf9O/03D55GJZX/fq4vIUxeLZPRpLZyBGP6X5bsUAeJ7vqG7yzRAli1eJMMGXyOnXnJ5cO9D74X8/NOP5b/cUwPk2fvvlJuffjkIGP3Zwp//K2df/Rf54esv5NrTjysPDQ2Ux268OrinsnXL1vK3W2+Q3x13UvA4DZNhN10n5113U4X7LdU1mU2A6FlIhw4dgmU1RG644YaNJbIIkMrugbx/w8bLV5Omiwx+cWMQ6D/rdv0JIqlnIPrvP8wr+1kmZzIVjAiQ0P9dsGP1AgQIz5BAINMA0V/0X3z4fnlg6C/30Q/cJeddf0twMzw1QBKBUWfLLSsEwdJFCyvcRK8uJJLDJfmGfdQBouvpWcjw4cPLl9YQCc5IsgiQ1HsgC34V6TNUpG=');

        TestObjectsFactory.initializeRestContext(null, '/file/upload');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(fileWrapper));
        FileUploadWebService.doPost();
        Test.stopTest();
    }
}