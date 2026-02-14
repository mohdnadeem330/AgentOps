import { LightningElement,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';
import fetchAllDocumentIDs from '@salesforce/apex/DownloadSODocsController.fetchAllDocumentIDs';

export default class DownloadSODocs extends LightningElement {
    @api recordId;
    isLoading=true;
    recordLoaded=false;
    
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.getAllDOcumentIds();
        }
    }

    
    getAllDOcumentIds(){
        
            fetchAllDocumentIDs({recordId : this.recordId })
            .then(data => {
                if(data && data != undefined && data !=''){
                    console.log(data);
                    window.location.href = data;
                }
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Unable to download files!',
                        variant: 'error'
                    })
                );
                this.isLoading=false;
                this.dispatchEvent(new CloseActionScreenEvent());
            });
        
    }
}