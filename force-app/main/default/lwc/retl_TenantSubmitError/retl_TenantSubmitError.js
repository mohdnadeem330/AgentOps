import { LightningElement } from 'lwc';
import Images from "@salesforce/resourceUrl/RETLTenantPortalImages";


export default class Retl_TenantSubmitError extends LightningElement {
     icon20image = Images + '/Request/icon20.png';
     showFirstScreenHandler() {
        this.showFirstScreen = true;
        this.showSecondScreen = false;
         this.callParent('block');
    }
    callParent(displayMsg){
        console.log('displayMsg',displayMsg);
       this.dispatchEvent(
            new CustomEvent('submiterrorscreencall', {
                detail: { display: displayMsg },
                bubbles: true,    //  allow event to bubble up
                composed: true    //  allow event to cross shadow DOM
            })
        );
    }
}