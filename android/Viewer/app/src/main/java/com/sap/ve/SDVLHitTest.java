package com.sap.ve;

public class SDVLHitTest {
    /// X, Y coordinates of the point in question
    public float[] screenCoordinate = new float[2];

    /// Output: identifier of the node that was hit. Or DVLID_INVALID if there are no 3D objects underneath the X, Y screen coordinate
    public long nodeID;

    /// Output: world coordinate of the hit (only valid if nodeID != DVLID_INVALID)
    public float[] worldCoordinate = new float[3];

    /// Output: local coordinate of the hit (only valid if nodeID != DVLID_INVALID). In local coordinates of m_idNode node.
    public float[] localCoordinate = new float[3];
}
