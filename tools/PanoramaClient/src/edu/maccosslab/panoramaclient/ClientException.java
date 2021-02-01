package edu.maccosslab.panoramaclient;

public class ClientException extends Exception
{
    public ClientException(String message)
    {
        super(message);
    }

    public ClientException(String message, Throwable cause)
    {
        super(message, cause);
    }
}
