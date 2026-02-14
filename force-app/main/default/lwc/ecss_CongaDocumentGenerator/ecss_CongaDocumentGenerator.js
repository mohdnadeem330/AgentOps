import { LightningElement,api,track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import generateCongaDocunentLink from '@salesforce/apex/ECSS_CongaDocumentGenerator.generateCongaComposerLink';
export default class Ecss_CongaDocumentGenerator extends NavigationMixin(LightningElement) {
    @api documentId;
    @api documentName;
    @api recordId;

    @track fileGenerationURL='';
    //using Connected Callback and an Imparetive method call so that this component can be used with any flow version.
    connectedCallback() {
        /*console.log('Connected Call Back: ');
        console.log('documentName: '+ this.documentName);
        console.log('recordId: '+this.recordId);
        console.log('documentId: '+this.documentId);*/
        this.generateDocument();
    }

    generateDocument(){
        generateCongaDocunentLink({documentType: this.documentName, recordId: this.recordId, documentId: this.documentId})
        //this method gets the Conga URL of the button and displays it in a new tab.
        .then(data=>{
            console.log('data: '+data);
            window.open(data,'_blank');
        }).catch(error=>{
            console.log('error: '+error);
            console.log('error: '+JSON.stringify(error));
        });
    }
}