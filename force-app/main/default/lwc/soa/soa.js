import { LightningElement ,track,api,wire} from 'lwc';
import getVFDomainURL from "@salesforce/apex/Utilities.getVFDomainURL";
import { NavigationMixin } from 'lightning/navigation';

export default class Soa extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showiframe = false;
    @track fullUrl;

    connectedCallback(){
        console.log('Sales Order Record - ' + this.recordId);
    }

    async handleSOAClick(event) {
        var mainUrl = await getVFDomainURL();
        this.fullUrl = mainUrl + '/apex/StatementOfAccountDocument?id='+this.recordId;
        console.log('Page URL - '+this.fullUrl);
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    url: '/apex/StatementOfAccountDocument?id='+this.recordId
                }
            }).then(url => { window.open(url) });
    }
}