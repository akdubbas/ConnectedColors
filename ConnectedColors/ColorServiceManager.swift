//
//  ColorServiceManager.swift
//  ConnectedColors
//
//  Created by Amith Dubbasi on 11/30/17.
//  Copyright © 2017 Example. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class ColorServiceManager : NSObject
{
    private let ColorServiceType = "example-color"
    private let myPeerID = MCPeerID(displayName : UIDevice.current.name)
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    var delegate : ColorServiceManagerDelegate?
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer : myPeerID,discoveryInfo : nil,serviceType : ColorServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType : ColorServiceType)
        super.init()
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    lazy var session : MCSession = {
        let session = MCSession(peer : self.myPeerID, securityIdentity : nil, encryptionPreference : .required)
        session.delegate = self;
        return session
    }()
    
    
    func send(colorName : String)
    {
         NSLog("%@", "sendColor: \(colorName) to \(session.connectedPeers.count) peers")
        if(session.connectedPeers.count > 0)
        {
            do
            {
                try self.session.send(colorName.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error
            {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
    }
}


extension ColorServiceManager : MCNearbyServiceAdvertiserDelegate
{
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
         NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
         NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true,self.session)
    }
}

extension ColorServiceManager : MCNearbyServiceBrowserDelegate
{
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "Peer ID : \(peerID)")
        
        //Invite Peers
        NSLog("%@", "Peer ID : \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "Peer : \(peerID) ..Lost")
    }
}

extension ColorServiceManager : MCSessionDelegate
{
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
         NSLog("%@", "peer \(peerID) didChangeState: \(state)")
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        
        let str = String(data: data, encoding: .utf8)!
        self.delegate?.colorChanged(manager: self, colorString: str)
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
          NSLog("%@", "didReceiveStream")
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
         NSLog("%@", "didStartReceivingResourceWithName")
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?)
    {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
}

protocol ColorServiceManagerDelegate
{
    func connectedDevicesChanged(manager : ColorServiceManager, connectedDevices: [String])
    func colorChanged(manager : ColorServiceManager, colorString: String)
}




