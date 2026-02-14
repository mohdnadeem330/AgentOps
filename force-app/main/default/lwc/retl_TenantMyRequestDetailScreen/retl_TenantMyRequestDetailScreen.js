import { LightningElement, api } from 'lwc';
export default class Retl_TenantMyRequestDetailScreen extends LightningElement {

    showFirstScreen = true;
    showSecondScreen = false;
    isLoading = false;
    @api recordId;
    @api selectedRecord = {};
    @api accessToken;
    @api requestSubmittingBy
    @api contactId
    urlParams;

    connectedCallback() {
        console.log('connectedCallback from detail screen');
        console.log('this.selectedRecord', JSON.stringify(this.selectedRecord));
        console.log('this.recordId', this.recordId);
        if (!this.recordId && this.selectedRecord && this.selectedRecord.caseId) {
            this.recordId = this.selectedRecord.caseId;
        }
        console.log('this.recordId', this.recordId);
        window.scrollTo(0, 0);

        console.log('window.location.href in connectedCallback==',window.location.href);
        let urlString = window.location.href;
        console.log('urlString==', urlString);
        let url = new URL(window.location.href);
        console.log('url==', url);
        console.log('url.searchParams==', url.searchParams);
        console.log('url.searchParams.get(id)==', url.searchParams.get('srId'));

        if(this.recordId && this.recordId.length > 0) {
            url.searchParams.set('srId', this.recordId.slice(3));
        }
        console.log('new url==', url);
        this.urlParams = url.searchParams;
        window.history.pushState({}, '', url);

        /*window.addEventListener('popstate', (event) => {
            console.log('popstate event fired');
            console.log('State:', event.state);
        });
        window.addEventListener('hashchange', (event) => {
            console.log('hashchange event fired');
        }); */
    }

    renderedCallback() {
        console.log('window.location.href in renderedCallback==',window.location.href);
    }

    disconnectedCallback() {
        console.log('disconnectedCallback from detail screen');
        // window.removeEventListener('popstate', );
    }

    showFirstScreenHandler() {
        this.showFirstScreen = true;
        this.showSecondScreen = false;

        let url = new URL(window.location.href);
        if(url.searchParams && url.searchParams.has('srId')) {
            url.searchParams.delete('srId');
            window.history.pushState({}, '', url);
        }
        console.log('new url==', url);

        this.callParent('block');
    }

    callParent(displayMsg) {
        console.log('displayMsg', displayMsg);
        this.dispatchEvent(
            new CustomEvent('call', {
                detail: { display: displayMsg },
                bubbles: true,    //allow event to bubble up
                composed: true    //allow event to cross shadow DOM
            })
        );
    }

}