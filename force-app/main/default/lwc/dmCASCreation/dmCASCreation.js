import { LightningElement, api, wire, track } from 'lwc';
import createAndLinkCASDocument from '@salesforce/apex/DMCaseSendDocToCustomer.createAndLinkDocument';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class DmCASCreation extends LightningElement {
    @api recordId ; 
    @track reportLink;
    @track activeTab = 0;
    showSpinner = false;
    isshowflow = false
    showTLAPopup = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId || this.recordId;
        }
    }
    
     connectedCallback() {
         this.showTLAPopup = true;
    } 
    
    handleSave(){
        this.createAndLinkCASDocument();
        this.showTLAPopup = false;
    }
    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
             this.showToast('Success', 'Documents has been updated successfully', 'success', 'dismissable');
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.dispatchEvent(new CloseActionScreenEvent());
                setTimeout(() => {
                    window.location.reload();
                }, 1000);
        }
    }
    createAndLinkCASDocument() {
        this.showSpinner = true;
        createAndLinkCASDocument({ caseId: this.recordId, docType: 'Draft CAS' })
        .then(result => {
                this.flowInputVariables = [

                    {
                        name: "docType",
                        type: "String",
                        value: 'Draft CAS',
                    },
                    {
                        name: "LoopDDPId",
                        type: "String",
                        value: result.LoopDDPId,
                    },
                    {
                        name: "LoopDDPRecordId",
                        type: "String",
                        value: result.LoopDDPRecordId,
                    },
                    {
                        name: "DocumentId",
                        type: "String",
                        value: result.DocumentId,
                    }
                ];
                this.isshowflow = true;
                this.showSpinner = false;


            })
            .catch(error => {
                this.showSpinner = false;
                //console.log('error--' + JSON.stringify(error));
            });
               
    }    
            
    
    closeScreen() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}