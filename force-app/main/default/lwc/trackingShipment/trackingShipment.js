import { LightningElement, track } from 'lwc';
import getTrackingDeatail from '@salesforce/apex/ShipmentRequestCalloutHelper.TrackingCallout';

export default class TrackingShipment extends LightningElement {
    @track recordId;

    @track trackingDeatail;
    @track trackingDeatailList = [];
    @track columns = [
        { label: 'Last Location', fieldName: 'trackingLocation' },
        { label: 'Last Update Date', fieldName: 'trackingDate' },
        { label: 'Description', fieldName: 'trackingDescription' },
    ];
    @track awbNumber = '';
    @track isLoading = false;

    async connectedCallback() {
        this.recordId = new URL(window.location.href).searchParams.get("recordId");
        this.isLoading = true;

        await getTrackingDeatail({
            srId: this.recordId
        }).then(result => {
            console.log('result>>>', result);
            this.trackingDeatail = JSON.parse(result);
            this.trackingDeatailList = [];
            if (this.trackingDeatail && this.trackingDeatail.TrackingResults && this.trackingDeatail.TrackingResults.length > 0) {
                let trackingResults = this.trackingDeatail.TrackingResults[0];
                if (trackingResults.Value && trackingResults.Value.length > 0) {
                    let val0 = trackingResults.Value[0];
                    this.awbNumber = val0.WaybillNumber;
                    for (let i = 0; i < trackingResults.Value.length; i++) {
                        let val = trackingResults.Value[i];
                        let tdMap = {};
                        tdMap.id = i;
                        tdMap.trackingDescription = val.UpdateDescription;
                        tdMap.trackingDate = (new Date(parseInt(val.UpdateDateTime.substring(val.UpdateDateTime.indexOf("(") + 1, val.UpdateDateTime.lastIndexOf("+"))))).toString();
                        tdMap.trackingLocation = val.UpdateLocation;
                        this.trackingDeatailList.push(tdMap);
                    }
                }
            }
            this.isLoading = false;
        }).catch(error => {
            this.isLoading = false;
            console.error('error>>>', error);
        })
    }
}