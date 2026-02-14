import { LightningElement,api,track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import generateCongaDocument from '@salesforce/apex/ECSS_CongaDocumentGenerator.generateCongaComposerLink';
export default class Ecss_CongaDocumentGeneration extends NavigationMixin(LightningElement){
    @api quoteId;
    @api leasingType;
    //@api documentId;

    @track fileGenerationURL='';
    @wire(generateCongaDocument, {leasingType: '$leasingType', quoteId: '$quoteId'/*, documentId: '$documentId'*/})
    generateDocument({data,error})
    {
        console.log('leasingType: '+this.leasingType);
        console.log('quoteId: '+this.quoteId);
        if(data){
            console.log('data: '+data);
            //fileGenerationURL = data;
            window.open(data,'_blank')
        }
        else if(error){
            console.log('error: '+error);
            console.log('error: '+JSON.stringify(error))
        }
    }
}