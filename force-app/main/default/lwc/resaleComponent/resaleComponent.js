import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class ResaleComponent extends LightningElement {
    @api reSaleValues; //UNIT RECORD RECEIVED
    initiateParent = {
        offerPrice:true,
        comments:false
    };

    handleLookupSelection(event){
        if(event.detail.selectedRecord != undefined){
            console.log('Selected Record Value on Parent Component is ' +  
            JSON.stringify(event.detail.selectedRecord));
            alert(event.detail.selectedRecord.Id + ' '+ event.detail.selectedRecord.Name);
        }
    }

    handleKeyUp(event) {
        let value = event.target.value;
        let name = event.target.name;

        if(name == 'Comments__c'){
            this.initiateParent.comments =  (value === undefined || value === '' || value === null) ? false : true;
        }
        if(name == 'Offer_Price__c'){
            this.initiateParent.offerPrice =  (value === undefined || value === '' || value === null) ? false : true;
        }

        console.log('#### initiateParent ',this.initiateParent);

        if(Object.values(this.initiateParent).every(item => item === true)){
            let objsObj = [];
            const inputFields = this.template.querySelectorAll('lightning-input');
            if(inputFields){
                let objData = {};
                inputFields.forEach(field =>{
                    console.log('####field name: ',field.name);
                    console.log('####field value: ',field.value);
                    objData[field.name] = field.value;
                });
                objData['Opportunity__c'] = this.reSaleValues.oppId;
                objData['Unit__c'] = this.reSaleValues.unitRecord.Id;
                objData['Case__c'] = this.reSaleValues.caseId;
                objData['Sales_Order__c'] = this.reSaleValues.salesOrderId;
                objData['Buyer_Account__c'] = this.reSaleValues.buyerAccount;
                objData['BuyerEmail__c'] = this.reSaleValues.buyerEmail;
                objData['BuyerPhone__c'] = this.reSaleValues.buyerPhone;
                objData['Seller_Account__c'] = this.reSaleValues.sellerAccount;
                objData['SellerEmail__c'] = this.reSaleValues.sellerEmail;
                objData['SellerPhone__c'] = this.reSaleValues.sellerPhone;

                objsObj.push(objData);
            }
            
            if(objsObj.length > 0){
                this.dispatchEvent(new CustomEvent('createresale', {detail : objsObj[0]}));
            }
        }
        else{
            this.dispatchEvent(new CustomEvent('createresale', {detail : null}));
        //    if(!this.initiateParent.listingPrice){
        //         this.handleToastMessage('Please enter Offer Price to proceed','error');
        //    }
        //    if(!this.initiateParent.comments){
        //         this.handleToastMessage('Please enter Comments to proceed','Comments','error');
        //    }
        }
    }

    handleToastMessage(message,title,variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }

    get getListedPrice() {
    // Use the toLocaleString() method with options for currency formatting
    return this.reSaleValues.unitRecord.Listing_Price__c.toLocaleString('ar-AE', { style: 'currency', currency: 'AED' });
    }
}