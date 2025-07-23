<?php
class ValidationException extends Exception
{
    private int $errorCode;

    public function __construct(string $message, int $errorCode = 1)
    {
        parent::__construct($message);
        $this->errorCode = $errorCode;
    }

    public function getErrorCode(): int
    {
        return $this->errorCode;
    }
}
