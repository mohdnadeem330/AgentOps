import { LightningElement, api, wire, track } from 'lwc';
import CreateDraftTLA from '@salesforce/apex/DMCaseSendDocToCustomer.createAndLinkDocument';
import genericValidationMsgGenerator from '@salesforce/apex/DM_UtilityController.genericValidationMsgGenerator';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class DmCreateCDADoc extends LightningElement {
    @api recordId;
    showSpinner = false;
    showCreateDraftTlaButton = false;
    showModal = false;
    showpreview = false;
    showErrorMsg = false;
    isEditMode = false;
    missingFields = [];
    @track reportLink;
    @track activeTab = 0;
    showEmailPopup = false;
    showTLAPopup = false;
    flowInputVariables;
    flowApiName = "GenerateDraftTLA";

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        this.validateFields();
    }
    validateFields() {
        genericValidationMsgGenerator({ recordId: this.recordId })
            .then(data => {
                this.showSpinner = false;
                if (data) {
                    this.missingFields = data.split(', ');
                    this.showErrorMsg = this.missingFields.length > 0;
                } else {
                    this.showTLAPopup = true;
                }
            })
            .catch(error => {
                this.showSpinner = false;
                //console.log('error->' + error.message);
                this.showToast('Error', 'Error creating document: ', 'error', 'dismissable');
            });
    }
     handleSave(){
        this.createTLA();
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
    createTLA() {
        this.showSpinner = true;
        CreateDraftTLA({ caseId: this.recordId, docType : 'Draft TLA' })
            .then(result => {
                this.flowInputVariables = [

                    {
                        name: "docType",
                        type: "String",
                        value: 'Draft TLA',
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
    closeModal() {
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