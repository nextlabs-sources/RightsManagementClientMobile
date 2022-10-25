package restAPIWithRMS;

/**
 * Created by oye on 10/15/2015.
 */
public interface Listener {
    void progress(int current, int total);

    void currentState(String state);
}
